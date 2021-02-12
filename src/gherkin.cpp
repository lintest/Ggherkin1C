﻿#include "gherkin.h"
#include "gherkin.lex.h"
#include <stdafx.h>
#include <codecvt>
#include <locale>
#include <stdio.h>
#include <reflex/matcher.h>
#include <boost/algorithm/string.hpp>
#include <boost/regex.hpp>

static bool comparei(const std::wstring& a, const std::wstring& b)
{
	static const std::locale locale_ru("ru_RU.UTF-8");
	return boost::iequals(a, b, locale_ru);
}

static FILE* fileopen(const BoostPath& path)
{
#ifdef _WINDOWS
	return _wfopen(path.wstring().c_str(), L"rb");
#else
	return fopen(path.string().c_str(), "rb");
#endif
}

namespace Gherkin {

	static std::string trim(const std::string& text)
	{
		static const std::string regex = reflex::Matcher::convert("\\S[\\s\\S]*\\S|\\S", reflex::convert_flag::unicode);
		static const reflex::Pattern pattern(regex);
		auto matcher = reflex::Matcher(pattern, text);
		return matcher.find() ? matcher.text() : std::string();
	}

	void set(JSON& json, const std::string& key, size_t value) {
		if (value != 0)
			json[key] = value;
	}

	void set(JSON& json, const std::string& key, const std::string& value) {
		if (!value.empty())
			json[key] = value;
	}

	void set(JSON& json, const std::string& key, const std::wstring& value) {
		if (!value.empty())
			json[key] = WC2MB(value);
	}

	void set(JSON& json, const std::string& key, const JSON& value) {
		if (!value.empty())
			json[key] = value;
	}

	void set(JSON& json, const std::string& key, const std::vector<std::string>& value) {
		if (!value.empty())
			json[key] = value;
	}

	void set(JSON& json, const std::string& key, const GherkinParams& value) {
		if (!value.empty()) {
			JSON js;
			for (const auto& [key, value] : value)
				js[WC2MB(key)] = value;

			json["params"] = js;
		}
	}

	template<typename T>
	void set(JSON& json, const std::string& key, const std::unique_ptr<T>& value) {
		if (value)
			json[key] = *value;
	}

	template<typename T>
	void set(JSON& json, const std::string& key, const std::vector<std::unique_ptr<T>>& value) {
		if (!value.empty()) {
			JSON js;
			for (auto& i : value)
				js.push_back(JSON(*i));

			json[key] = js;
		}
	}

	enum class MatchType {
		Include,
		Exclude,
		Unknown
	};

	class GherkinFilter {
	private:
		std::set<std::wstring> include;
		std::set<std::wstring> exclude;
	public:
		GherkinFilter(const std::string& text) {
			if (text.empty())
				return;

			auto json = JSON::parse(text);

			for (auto& tag : json["include"]) {
				include.emplace(lower(MB2WC(tag)));
			}

			for (auto& tag : json["exclude"]) {
				exclude.emplace(lower(MB2WC(tag)));
			}
		}
		MatchType match(const StringLines& tags) const {
			if (!exclude.empty())
				for (auto& tag : tags) {
					if (exclude.find(lower(tag.wstr)) != exclude.end())
						return MatchType::Exclude;
				}
			if (include.empty())
				return MatchType::Include;
			else {
				for (auto& tag : tags) {
					if (include.find(lower(tag.wstr)) != include.end())
						return MatchType::Include;
				}
				return MatchType::Unknown;
			}
		}
		bool match(const GherkinDocument& doc) const {
			switch (match(doc.getTags())) {
			case MatchType::Exclude: return false;
			case MatchType::Include: return true;
			default: return include.empty();
			}
		}
	};

	GherkinProvider::Keyword::Keyword(KeywordType type, const std::string& text)
		:type(type), text(text)
	{
		static const std::string regex = reflex::Matcher::convert("\\w+", reflex::convert_flag::unicode);
		static const reflex::Pattern pattern(regex);
		auto matcher = reflex::Matcher(pattern, text);
		while (matcher.find() != 0) {
			words.push_back(matcher.wstr());
		}
	}

	GherkinKeyword* GherkinProvider::Keyword::match(GherkinTokens& tokens) const
	{
		if (words.size() > tokens.size())
			return nullptr;

		for (size_t i = 0; i < words.size(); ++i) {
			if (tokens[i].type != TokenType::Operator)
				return nullptr;

			if (!comparei(words[i], tokens[i].wstr))
				return nullptr;
		}

		bool toplevel = false;
		size_t keynum = words.end() - words.begin();
		for (auto& t : tokens) {
			if (keynum > 0) {
				t.type = TokenType::Keyword;
				keynum--;
			}
			else {
				if (t.type == TokenType::Colon)
					toplevel = true;
				break;
			}
		}

		return new GherkinKeyword(*this, toplevel);
	}

	std::string GherkinProvider::getKeywords() const
	{
		JSON json;
		for (auto& language : keywords) {
			JSON js;
			for (auto& keyword : language.second) {
				auto type = GherkinKeyword::type2str(keyword.type);
				js[type].push_back(keyword.text);
			}
			json[language.first] = js;
		}
		return json.dump();
	}

	void GherkinProvider::setKeywords(const std::string& text)
	{
		auto json = JSON::parse(text);
		keywords.clear();
		for (auto lang = json.begin(); lang != json.end(); ++lang) {
			std::string language = lang.key();
			auto& vector = keywords[language];
			auto& types = lang.value();
			for (auto type = types.begin(); type != types.end(); ++type) {
				KeywordType t = GherkinKeyword::str2type(type.key());
				auto& words = type.value();
				if (words.is_array()) {
					for (auto word = words.begin(); word != words.end(); ++word) {
						std::string text = trim(*word);
						if (text == "*") continue;
						vector.push_back({ t, *word });
					}
				}
			}
			std::sort(vector.begin(), vector.end(),
				[](const Keyword& a, const Keyword& b) -> bool { return a.comp(b); }
			);
		}
	}

	GherkinKeyword* GherkinProvider::matchKeyword(const std::string& lang, GherkinTokens& tokens) const
	{
		std::string language = lang.empty() ? std::string("ru") : lang;
		for (auto& keyword : keywords.at(language)) {
			auto matched = keyword.match(tokens);
			if (matched) return matched;
		}
		return nullptr;
	}

	void GherkinProvider::ClearSnippets(const BoostPath& path)
	{
		if (path.empty()) {
			snippets.clear();
			return;
		}

		bool exists = true;
		while (exists) {
			exists = false;
			for (auto it = snippets.begin(); it != snippets.end(); ++it) {
				if (it->second.filepath == path) {
					snippets.erase(it);
					exists = true;
					break;
				}
			}
		}
	}

	class GherkinProvider::ScanParams {
	public:
		ScanParams(const std::string& filter) : filter(filter) {}
		std::set<BoostPath> ready;
		GherkinFilter filter;
		FileCache cashe;
		JSON json;
	};

	BoostPaths GherkinProvider::GetDirFiles(size_t id, const BoostPath& root) const
	{
		BoostPaths files;
		const std::wstring mask = L"^.+\\.feature$";
		boost::wregex pattern(mask, boost::regex::icase);
		boost::filesystem::recursive_directory_iterator end_itr;
		for (boost::filesystem::recursive_directory_iterator i(root); i != end_itr; ++i) {
			if (id != identifier) return {};
			if (boost::filesystem::is_regular_file(i->status())) {
				boost::wsmatch what;
				std::wstring path = i->path().wstring();
				std::wstring name = i->path().filename().wstring();
				if (boost::regex_match(name, what, pattern))
					files.push_back(path);
			}
		}
		return files;
	}

	void GherkinProvider::ScanFolder(size_t id, AbstractProgress* progress, const BoostPath& root, ScanParams& params)
	{
		if (root.empty()) return;
		auto files = GetDirFiles(id, root);
		if (progress) progress->Start(WC2MB(root.wstring()), files.size(), "scan");

		for (auto& path : files) {
			if (id != identifier) return;
			if (progress) progress->Step(path);
			auto doc = std::make_unique<GherkinDocument>(*this, path);
			doc->getExportSnippets(snippets);
			params.cashe.emplace(path, doc.release());
		}
	}

	void GherkinProvider::DumpFolder(size_t id, AbstractProgress* progress, const BoostPath& root, ScanParams& params)
	{
		if (root.empty()) return;
		auto files = GetDirFiles(id, root);
		if (progress) progress->Start(WC2MB(root.wstring()), files.size(), "dump");

		for (auto& path : files) {
			if (id != identifier) return;
			if (progress) progress->Step(path);
			if (params.ready.count(path) != 0) continue;
			params.ready.insert(path);
			std::unique_ptr<GherkinDocument> doc;
			auto it = params.cashe.find(path);
			if (it == params.cashe.end())
				doc.reset(new GherkinDocument(*this, path));
			else {
				doc.reset(it->second.release());
				params.cashe.erase(it);
			}
			doc->generate(snippets);
			auto js = doc->dump(params.filter);
			if (!js.empty())
				params.json.push_back(js);
		}
	}

	std::string GherkinProvider::ParseFolder(const std::string& dirs, const std::string& libs, const std::string& tags, AbstractProgress* progress)
	{
		if (dirs.empty()) return {};
		size_t id = identifier;
		ScanParams params(tags);
		JSON directories, libraries;

		try {
			directories = JSON::parse(dirs);
		}
		catch (...) {
			directories.push_back(dirs);
		}

		try {
			if (!libs.empty())
				libraries = JSON::parse(libs);
		}
		catch (...) {
			libraries.push_back(libs);
		}

		for (auto& dir : libraries) {
			ScanFolder(id, progress, MB2WC(dir), params);
		}

		for (auto& dir : directories) {
			DumpFolder(id, progress, MB2WC(dir), params);
		}

		return params.json.dump();
	}

	std::string GherkinProvider::ParseFile(const std::wstring& path, const std::string& libs, AbstractProgress* progress)
	{
		if (path.empty()) return {};
		size_t id = identifier;
		ScanParams params({});
		JSON libraries;

		try {
			if (!libs.empty())
				libraries = JSON::parse(libs);
		}
		catch (...) {
			libraries.push_back(libs);
		}

		for (auto& dir : libraries) {
			ScanFolder(id, progress, MB2WC(dir), params);
		}

		std::unique_ptr<GherkinDocument> doc;
		auto it = params.cashe.find(path);
		if (it == params.cashe.end())
			doc.reset(new GherkinDocument(*this, path));
		else {
			doc.reset(it->second.release());
		}
		doc->generate(snippets);
		return JSON(*doc).dump();
	}

	std::string GherkinProvider::ParseText(const std::string& text)
	{
		if (text.empty()) return {};
		GherkinDocument doc(*this, text);
		doc.generate(snippets);
		return JSON(doc).dump();
	}

	KeywordType GherkinKeyword::str2type(const std::string& text)
	{
		std::string type = text;
		transform(type.begin(), type.end(), type.begin(), tolower);
		static std::map<std::string, KeywordType> types{
			{ "and", KeywordType::And},
			{ "background", KeywordType::Background },
			{ "but", KeywordType::But },
			{ "examples", KeywordType::Examples },
			{ "feature", KeywordType::Feature },
			{ "if", KeywordType::If },
			{ "given", KeywordType::Given },
			{ "rule", KeywordType::Rule },
			{ "scenario", KeywordType::Scenario },
			{ "scenariooutline", KeywordType::ScenarioOutline },
			{ "then", KeywordType::Then },
			{ "when", KeywordType::When },
		};
		auto it = types.find(type);
		return it == types.end() ? KeywordType::None : it->second;
	}

	std::string GherkinKeyword::type2str(KeywordType type)
	{
		switch (type) {
		case KeywordType::And: return "And";
		case KeywordType::Background: return "Background";
		case KeywordType::But: return "But";
		case KeywordType::Examples: return "Examples";
		case KeywordType::Feature: return "Feature";
		case KeywordType::Given: return "Given";
		case KeywordType::Scenario: return "Scenario";
		case KeywordType::ScenarioOutline: return "ScenarioOutline";
		case KeywordType::Rule: return "Rule";
		case KeywordType::Then: return "Then";
		case KeywordType::When: return "When";
		default: return "None";
		}
	}

	GherkinKeyword::operator JSON() const
	{
		JSON json;
		json["text"] = text;
		json["type"] = type2str(type);
		if (toplevel)
			json["toplevel"] = toplevel;

		return json;
	}

	StringLine::StringLine(const GherkinLexer& lexer)
		: wstr(lexer.wstr()), text(lexer.text()), lineNumber(lexer.lineno())
	{
	}

	StringLine::StringLine(const GherkinLine& line)
		: text(trim(line.getText())), wstr(MB2WC(text)), lineNumber(line.getLineNumber())
	{
	}

	StringLine::StringLine(const StringLine& src)
		: wstr(src.wstr), text(src.text), lineNumber(src.lineNumber) 
	{
	}

	StringLine::operator JSON() const
	{
		JSON json;
		set(json, "text", text);
		set(json, "line", lineNumber);
		return json;
	}

	GherkinToken& GherkinToken::operator=(const GherkinToken& src)
	{
		type = src.type;
		wstr = src.wstr;
		text = src.text;
		column = src.column;
		symbol = src.symbol;
		return *this;
	}

	GherkinToken::GherkinToken(GherkinLexer& lexer, TokenType type, char ch)
		: type(type), wstr(lexer.wstr()), text(lexer.text()), column(lexer.columno()), symbol(ch)
	{
		if (ch != 0) {
			bool escaping = false;
			std::wstringstream ss;
			for (auto it = wstr.begin(); it != wstr.end(); ++it) {
				if (it == wstr.begin() || (it + 1) == wstr.end())
					continue;

				if (escaping) {
					escaping = false;
					wchar_t wc = *it;
					switch (wc) {
					case L'\"': ss << L'\"'; break;
					case L'\'': ss << L'\''; break;
					case L't': ss << L'\t'; break;
					case L'n': ss << L'\n'; break;
					case L'r': ss << L'\r'; break;
					default:
						if (lexer.isPrimitiveEscaping())
							ss << L'\\';
						ss << wc;
					}
				}
				else {
					if (*it == L'\\')
						escaping = true;
					else
						ss << *it;
				}
			}
			wstr = ss.str();
			text = WC2MB(wstr);
		}
		else {
			text = trim(text);
			wstr = MB2WC(text);
		}
	}

	void GherkinToken::replace(const GherkinParams& params)
	{
		if (type == TokenType::Param) {
			auto key = lower(getWstr());
			auto it = params.find(key);
			if (it != params.end()) {
				*this = it->second;
			}
		}
	}

	std::wstringstream& operator<<(std::wstringstream& os, const GherkinToken& token)
	{
		if (token.symbol)
			os << MB2WC(std::string(1, (token.symbol == '>' ? '<' : token.symbol)));

		os << token.wstr;

		if (token.symbol)
			os << MB2WC(std::string(1, (token.symbol == '<' ? '>' : token.symbol)));

		return os;
	}

	GherkinToken::operator JSON() const
	{
		JSON json;
		json["text"] = text;
		json["column"] = column;
		json["type"] = type2str();

		if (symbol != 0)
			json["symbol"] = std::string(1, symbol);

		return json;
	}

	std::string GherkinToken::type2str() const
	{
		switch (type) {
		case TokenType::Language: return "Language";
		case TokenType::Encoding: return "Encoding";
		case TokenType::Asterisk: return "Asterisk";
		case TokenType::Operator: return "Operator";
		case TokenType::Comment: return "Comment";
		case TokenType::Keyword: return "Keyword";
		case TokenType::Number: return "Number";
		case TokenType::Colon: return "Colon";
		case TokenType::Param: return "Param";
		case TokenType::Table: return "Table";
		case TokenType::Cell: return "Cell";
		case TokenType::Line: return "Line";
		case TokenType::Date: return "Date";
		case TokenType::Text: return "Text";
		case TokenType::Tag: return "Tag";
		case TokenType::Symbol: return "Symbol";
		case TokenType::Multiline: return "Multiline";
		default: return "None";
		}
	}

	GherkinLine::GherkinLine(GherkinLexer& l)
		: lineNumber(l.lineno()), text(l.matcher().line())
	{
		std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> converter;
		wstr = converter.from_bytes(text);
	}

	GherkinLine::GherkinLine(size_t lineNumber)
		: lineNumber(lineNumber)
	{
	}

	void GherkinLine::push(GherkinLexer& lexer, TokenType type, char ch)
	{
		tokens.emplace_back(lexer, type, ch);
	}

	GherkinKeyword* GherkinLine::matchKeyword(GherkinDocument& document)
	{
		if (tokens.size() == 0) return nullptr;
		if (tokens.begin()->type != TokenType::Operator) return nullptr;
		keyword.reset(document.matchKeyword(tokens));
		//TODO: check does colon exists for top level keywords: Feature, Background, Scenario...
		return keyword.get();
	}

	GherkinSnippet snippet(const GherkinTokens& tokens)
	{
		std::wstringstream ss;
		for (auto& token : tokens) {
			if (token.getType() == TokenType::Operator) {
				ss << lower(token.getWstr());
			}
		}
		return ss.str();
	}

	GherkinLine::operator JSON() const
	{
		JSON json;
		set(json, "text", text);
		set(json, "line", lineNumber);
		set(json, "tokens", tokens);
		set(json, "keyword", keyword);
		return json;
	}

	Gherkin::TokenType GherkinLine::getType() const
	{
		return tokens.empty() ? TokenType::None : tokens.begin()->type;
	}

	int GherkinLine::getIndent() const
	{
		int indent = 0;
		const int tabSize = 4;
		for (auto ch : text) {
			switch (ch) {
			case ' ':
				indent++;
				break;
			case '\t':
				indent = indent + tabSize - (indent % tabSize);
				break;
			default:
				return indent;
			}
		}
		return INT_MAX;
	}

	GherkinTable::GherkinTable(const GherkinLine& line)
		: lineNumber(line.getLineNumber())
	{
		for (auto& token : line.getTokens()) {
			if (token.getType() == TokenType::Cell)
				head.push_back(token);
		}
	}

	GherkinTable::GherkinTable(const GherkinTable& src, const GherkinParams& params)
		: lineNumber(0)
	{
		for (auto& token : src.head) {
			head.emplace_back(token);
			head.back().replace(params);
		}
		for (auto& src_row : src.body) {
			body.push_back({});
			auto& row = body.back();
			for (auto& cell : src_row) {
				row.emplace_back(cell);
				row.back().replace(params);
			}
		}
	}

	GherkinTable& GherkinTable::operator=(const GherkinTable& src)
	{
		head = src.head;
		body = src.body;
		return *this;
	}

	void GherkinTable::push(const GherkinLine& line)
	{
		body.push_back({});
		auto& row = body.back();
		for (auto& token : line.getTokens()) {
			if (token.getType() == TokenType::Cell)
				row.push_back(token);
		}
	}

	GherkinTable::operator JSON() const
	{
		JSON json;
		set(json, "line", lineNumber);
		json["head"] = head;
		json["body"] = body;
		return json;
	}

	GeneratedScript* GeneratedScript::generate(const GherkinStep& owner, const ScenarioMap& map, const SnippetStack& stack)
	{
		auto snippet = owner.getSnippet();
		if (snippet.empty())
			return nullptr;

		if (stack.count(snippet))
			return nullptr;

		auto it = map.find(snippet);
		if (it == map.end())
			return nullptr;

		SnippetStack next = stack;
		next.insert(snippet);

		const ExportScenario& definition = it->second;
		auto result = std::make_unique<GeneratedScript>(owner, definition);
		for (auto& step : result->steps)
			step->generate(map, next);

		return result.release();
	}

	GeneratedScript::GeneratedScript(const GherkinStep& owner, const ExportScenario& definition)
		: filename(WC2MB(definition.filepath.wstring())), snippet(definition.getSnippet())
	{
		std::vector<GherkinToken> source, target;
		for (auto& token : owner.getTokens()) {
			switch (token.getType()) {
			case TokenType::Param:
			case TokenType::Number:
			case TokenType::Date:
				source.push_back(token);
				break;
			}
		}
		for (auto& token : definition.getTokens()) {
			switch (token.getType()) {
			case TokenType::Param:
			case TokenType::Number:
			case TokenType::Date:
				target.push_back(token);
				break;
			}
		}
		auto s = source.begin();
		auto t = target.begin();
		while (s != source.end() && t != target.end()) {
			if (t->getType() == TokenType::Param) {
				auto key = lower(t->getWstr());
				if (params.count(key) == 0)
					params.emplace(key, *s);
				else
					throw GherkinException("Duplicate param keys");
			}
			++s;
			++t;
		}
		for (auto& step : definition.steps) {
			steps.emplace_back(step->copy(params));
		}
	}

	void GeneratedScript::replace(GherkinTables& tabs)
	{
		for (auto& step : steps) {
			step->replace(tabs);
		}
	}

	GeneratedScript::operator JSON() const
	{
		JSON json;
		set(json, "key", snippet);
		set(json, "filename", filename);
		set(json, "params", params);
		set(json, "steps", steps);
		return json;
	}

	static void set_params(JSON& json, const GherkinTokens& tokens)
	{
		JSON params;
		for (auto& token : tokens) {
			switch (token.getType()) {
			case TokenType::Param:
			case TokenType::Number:
			case TokenType::Date:
				params.push_back(token);
			}
		}
		set(json, "params", params);
	}

	GherkinElement::GherkinElement(const GherkinElement& src, const GherkinParams& params)
		: wstr(src.wstr), text(src.text), lineNumber(0)
	{
		for (auto& step : src.steps) {
			steps.emplace_back(step->copy(params));
		}
		for (auto& table : src.tables) {
			tables.emplace_back(table, params);
		}
	}

	GherkinElement::GherkinElement(GherkinLexer& lexer, const GherkinLine& line)
		: wstr(line.getWstr()), text(line.getText()), lineNumber(line.getLineNumber())
	{
		comments = std::move(lexer.commentStack);
		tags = std::move(lexer.tagStack);
	}

	void GherkinElement::generate(const ScenarioMap& map, const SnippetStack& stack)
	{
		for (auto& it : steps)
			it->generate(map, stack);
	}

	GherkinElement* GherkinElement::push(GherkinLexer& lexer, const GherkinLine& line)
	{
		GherkinElement* element = nullptr;
		switch (line.getType()) {
		case TokenType::Keyword:
			element = new GherkinStep(lexer, line);
			break;
		case TokenType::Asterisk:
		case TokenType::Operator:
		case TokenType::Symbol:
			element = new GherkinGroup(lexer, line);
			break;
		default:
			return nullptr;
		}
		steps.emplace_back(element);
		return element;
	}

	GherkinTable* GherkinElement::pushTable(const GherkinLine& line)
	{
		tables.push_back(line);
		return &tables.back();
	}

	void GherkinElement::replace(GherkinTables& tabs)
	{
		for (auto& table : tables) {
			if (tabs.empty()) return;
			auto t = tabs.back();
			if (!t.empty()) table = t;
			tabs.pop_back();
		}
		for (auto& it : steps)
			it->replace(tabs);
	}

	GherkinElement* GherkinElement::copy(const GherkinParams& params) const
	{
		return new GherkinElement(*this, params);
	}

	GherkinElement::operator JSON() const
	{
		JSON json;
		set(json, "text", text);
		set(json, "line", lineNumber);
		set(json, "snippet", getSnippet());
		set(json, "steps", steps);
		set(json, "tables", tables);
		set(json, "tags", tags);
		set(json, "comments", comments);
		return json;
	}

	AbsractDefinition::AbsractDefinition(GherkinLexer& lexer, const GherkinLine& line)
		: GherkinElement(lexer, line), keyword(*line.getKeyword())
	{
		std::string text = line.getText();
		static const std::string regex = reflex::Matcher::convert("[^:]+:\\s*", reflex::convert_flag::unicode);
		static const reflex::Pattern pattern(regex);
		auto matcher = reflex::Matcher(pattern, text);
		if (matcher.find() && matcher.size() < text.size()) {
			name = trim(text.substr(matcher.size()));
		}
	}

	AbsractDefinition::AbsractDefinition(const GherkinDocument& doc, const AbsractDefinition& def)
		: GherkinElement(def, {}), name(name), keyword(keyword)
	{
	}

	GherkinElement* AbsractDefinition::push(GherkinLexer& lexer, const GherkinLine& line)
	{
		return GherkinElement::push(lexer, line);
	}

	AbsractDefinition::operator JSON() const
	{
		JSON json = GherkinElement::operator JSON();
		set(json, "name",  name);
		return json;
	}

	GherkinFeature::GherkinFeature(GherkinLexer& lexer, const GherkinLine& line)
		: AbsractDefinition(lexer, line)
	{
	}

	GherkinElement* GherkinFeature::push(GherkinLexer& lexer, const GherkinLine& line)
	{
		description.emplace_back(line);
		return nullptr;
	}

	GherkinFeature::operator JSON() const
	{
		JSON json = AbsractDefinition::operator JSON();
		json["keyword"] = keyword;
		set(json, "description", description);
		return json;
	}

	GherkinDefinition::GherkinDefinition(GherkinLexer& lexer, const GherkinLine& line)
		: AbsractDefinition(lexer, line), tokens(line.getTokens())
	{
	}

	GherkinDefinition::GherkinDefinition(const GherkinDocument& doc, const GherkinDefinition& def)
		: AbsractDefinition(doc, def), tokens(def.tokens)
	{
	}

	GherkinElement* GherkinDefinition::push(GherkinLexer& lexer, const GherkinLine& line)
	{
		auto keyword = line.getKeyword();
		if (keyword && keyword->getType() == KeywordType::Examples) {
			if (examples)
				throw GherkinException(lexer, "Examples duplicate error");

			examples.reset(new GherkinStep(lexer, line));
			return examples.get();
		}
		else
			return GherkinElement::push(lexer, line);
	}

	GherkinSnippet GherkinDefinition::getSnippet() const
	{
		return snippet(tokens);
	}

	GherkinDefinition::operator JSON() const
	{
		JSON json = AbsractDefinition::operator JSON();
		json["keyword"] = keyword;
		set(json, "tokens", tokens);
		set(json, "examples", examples);
		set_params(json, tokens);
		return json;
	}

	GherkinStep::GherkinStep(GherkinLexer& lexer, const GherkinLine& line)
		: GherkinElement(lexer, line), keyword(*line.getKeyword()), tokens(line.getTokens())
	{
	}

	GherkinStep::GherkinStep(const GherkinStep& src, const GherkinParams& params)
		: GherkinElement(src, params), keyword(src.keyword), tokens(src.tokens)
	{
		bool split = false;
		const wchar_t splitter = L' ';
		std::wstringstream ss;
		for (auto& token : tokens) {
			token.replace(params);
			if (split) {
				if (token.getType() != TokenType::Symbol)
					ss << splitter;
			}
			else {
				split = true;
			}
			ss << token;
		}
		wstr = ss.str();
		text = WC2MB(wstr);
	}

	GherkinElement* GherkinStep::copy(const GherkinParams& params) const
	{
		return new GherkinStep(*this, params);
	}

	void GherkinStep::generate(const ScenarioMap& map, const SnippetStack& stack)
	{
		script.reset(GeneratedScript::generate(*this, map, stack));
		GherkinElement::generate(map, stack);
		
		if (script) {
			GherkinTables tabs;
			for (auto it = tables.rbegin(); it != tables.rend(); ++it) {
				tabs.push_back(*it);
			}
			script->replace(tabs);
		}
	}

	GherkinSnippet GherkinStep::getSnippet() const
	{
		return snippet(tokens);
	}

	GherkinStep::operator JSON() const
	{
		JSON json = GherkinElement::operator JSON();
		json["keyword"] = keyword;
		set(json, "tokens", tokens);
		set(json, "snippet", script);
		set_params(json, tokens);
		return json;
	}

	GherkinGroup::GherkinGroup(const GherkinGroup& src, const GherkinParams& params)
		: GherkinElement(src, params), name(src.name)
	{
	}

	GherkinGroup::GherkinGroup(GherkinLexer& lexer, const GherkinLine& line)
		: GherkinElement(lexer, line), name(trim(line.getText()))
	{
	}

	GherkinElement* GherkinGroup::copy(const GherkinParams& params) const
	{
		return new GherkinGroup(*this, params);
	}

	GherkinGroup::operator JSON() const
	{
		JSON json = GherkinElement::operator JSON();
		json["name"] = name;
		return json;
	}

	ExportScenario::ExportScenario(const ScenarioRef& ref)
		: GherkinDefinition(ref.first, ref.second), filepath(ref.first.filepath)
	{
	}

	GherkinException::GherkinException(GherkinLexer& lexer, const std::string& message)
		: std::runtime_error(message.c_str()), line(lexer.lineno()), column(lexer.columno())
	{
	}

	GherkinException::GherkinException(GherkinLexer& lexer, char const* const message)
		: std::runtime_error(message), line(lexer.lineno()), column(lexer.columno())
	{
	}

	GherkinException::GherkinException(const GherkinException& src)
		: std::runtime_error(*this), line(src.line), column(src.column)
	{
	}

	GherkinException::GherkinException(char const* const message)
		: std::runtime_error(message), line(0), column(0)
	{
	}

	GherkinException::operator JSON() const
	{
		JSON json;
		json["line"] = line;
		json["column"] = column;
		json["message"] = what();
		return json;
	}

	GherkinError::GherkinError(GherkinLexer& lexer, const std::string& message)
		: line(lexer.lineno()), column(lexer.columno()), message(message)
	{
	}

	GherkinError::GherkinError(size_t line, const std::string& message)
		: line(line), column(0), message(message)
	{
	}

	GherkinError::operator JSON() const
	{
		JSON json;
		set(json, "line", line);
		set(json, "column", column);
		set(json, "text", message);
		return json;
	}

	GherkinDocument::GherkinDocument(GherkinProvider& provider, const BoostPath& path)
		: provider(provider), filepath(path), filetime(boost::filesystem::last_write_time(path))
	{
		try {
			std::unique_ptr<FILE, decltype(&fclose)> file(fileopen(path), &fclose);
			reflex::Input input(file.get());
			GherkinLexer lexer(input);
			lexer.parse(*this);
		}
		catch (const std::exception& e) {
			errors.emplace_back(e);
		}
	}

	GherkinDocument::GherkinDocument(GherkinProvider& provider, const std::string& text)
		: provider(provider), filetime(0)
	{
		if (text.empty()) return;
		try {
			reflex::Input input(text);
			GherkinLexer lexer(input);
			lexer.parse(*this);
		}
		catch (const std::exception& e) {
			errors.emplace_back(e);
		}
	}

	void GherkinDocument::setLanguage(GherkinLexer& lexer)
	{
		if (language.empty())
			language = trim(lexer.text());
		else
			error(lexer, "Language key duplicate error");
	}

	void GherkinDocument::resetElementStack(GherkinLexer& lexer, GherkinElement& element)
	{
		lexer.lastElement = &element;
		lexer.elementStack.clear();
		lexer.elementStack.emplace_back(-2, &element);
	}

	void GherkinDocument::setDefinition(AbsractDef& definition, GherkinLexer& lexer, GherkinLine& line)
	{
		if (definition) {
			auto keyword = line.getKeyword();
			if (keyword) {
				std::string type = GherkinKeyword::type2str(keyword->getType());
				error(line, type + " keyword duplicate error");
			}
			else
				error(line, "Unknown keyword type");
		}
		else {
			GherkinDefinition* def =
				line.getKeyword()->getType() == KeywordType::Feature
				? (GherkinDefinition*) new GherkinFeature(lexer, line)
				: new GherkinDefinition(lexer, line);
			definition.reset(def);
			resetElementStack(lexer, *def);
		}
	}

	void GherkinDocument::addScenarioDefinition(GherkinLexer& lexer, GherkinLine& line)
	{
		scenarios.emplace_back(std::make_unique<GherkinDefinition>(lexer, line));
		resetElementStack(lexer, *scenarios.back().get());
	}

	void GherkinDocument::addScenarioExamples(GherkinLexer& lexer, GherkinLine& line)
	{
		auto it = lexer.elementStack.begin();
		if (it == lexer.elementStack.end() || it->second->getType() != KeywordType::ScenarioOutline)
			throw GherkinException(lexer, "Parent element <Scenario outline> not found for <Examples>");

		while (lexer.elementStack.size() > 1)
			lexer.elementStack.pop_back();

		auto parent = lexer.elementStack.back().second;
		if (auto element = parent->push(lexer, line)) {
			lexer.elementStack.emplace_back(-1, element);
			lexer.lastElement = element;
		}
	}

	GherkinKeyword* GherkinDocument::matchKeyword(GherkinTokens& line)
	{
		return provider.matchKeyword(language, line);
	}

	void GherkinDocument::exception(GherkinLexer& lexer, const char* message)
	{
		std::stringstream stream_message;
		stream_message << (message != NULL ? message : "lexer error") << " at " << lexer.lineno() << ":" << lexer.columno();
		throw GherkinException(lexer, stream_message.str());
	}

	void GherkinDocument::error(GherkinLexer& lexer, const std::string& error)
	{
		errors.emplace_back(lexer, error);
	}

	void GherkinDocument::error(GherkinLine& line, const std::string& error)
	{
		errors.emplace_back(line.getLineNumber(), error);
	}

	void GherkinDocument::push(GherkinLexer& lexer, TokenType type, char ch)
	{
		if (lexer.currentLine == nullptr) {
			lexer.lines.push_back({ lexer });
			lexer.currentLine = &lexer.lines.back();
		}
		lexer.currentLine->push(lexer, type, ch);
		switch (type) {
		case TokenType::Language:
			setLanguage(lexer);
			break;
		case TokenType::Comment:
			lexer.commentStack.emplace_back(lexer);
			break;
		case TokenType::Tag:
			lexer.tagStack.emplace_back(lexer);
			break;
		}
	}

	void GherkinDocument::addTableLine(GherkinLexer& lexer, GherkinLine& line)
	{
		if (lexer.lastElement) {
			if (lexer.currentTable)
				lexer.currentTable->push(line);
			else {
				lexer.currentTable = lexer.lastElement->pushTable(line);
			}
		}
		else {
			//TODO: save error to error list
		}
	}

	void GherkinDocument::addElement(GherkinLexer& lexer, GherkinLine& line)
	{
		auto indent = line.getIndent();
		while (!lexer.elementStack.empty()) {
			if (lexer.elementStack.back().first < indent) break;
			lexer.elementStack.pop_back();
		}
		if (lexer.elementStack.empty()) {
			throw GherkinException(lexer, "Element statck is empty");
		}
		auto parent = lexer.elementStack.back().second;
		if (auto element = parent->push(lexer, line)) {
			lexer.elementStack.emplace_back(indent, element);
			lexer.lastElement = element;
		}
	}

	void GherkinDocument::processLine(GherkinLexer& lexer, GherkinLine& line)
	{
		if (line.getType() != TokenType::Table)
			lexer.currentTable = nullptr;

		auto keyword = line.matchKeyword(*this);
		if (keyword) {
			switch (keyword->getType()) {
			case KeywordType::Feature:
				setDefinition(feature, lexer, line);
				break;
			case KeywordType::Background:
				setDefinition(background, lexer, line);
				break;
			case KeywordType::Scenario:
			case KeywordType::ScenarioOutline:
				addScenarioDefinition(lexer, line);
				break;
			case KeywordType::Examples:
				addScenarioExamples(lexer, line);
				break;
			default:
				addElement(lexer, line);
			}
		}
		else {
			switch (line.getType()) {
			case TokenType::Asterisk:
			case TokenType::Operator:
			case TokenType::Symbol:
				addElement(lexer, line);
				break;
			case TokenType::Table:
				addTableLine(lexer, line);
				break;
			case TokenType::Multiline:
				//TODO: add multy line
				break;
			}
		}
	}

	void GherkinDocument::next(GherkinLexer& lexer)
	{
		if (lexer.currentLine) {
			processLine(lexer, *lexer.currentLine);
			lexer.currentLine = nullptr;
		}
		else {
			auto lineNumber = lexer.lineno();
			if (lineNumber > 1) {
				lexer.lines.push_back({ lineNumber });
				processLine(lexer, lexer.lines.back());
			}
			return;
		}
	}

	static bool hasExportSnippets(const StringLines& tags)
	{
		const std::string test = "ExportScenarios";
		for (auto& tag : tags) {
			if (boost::iequals(tag.text, test)) {
				return true;
			}
		}
		return false;
	}

	void GherkinDocument::getExportSnippets(ScenarioMap& snippets) const
	{
		provider.ClearSnippets(filepath);
		bool all = hasExportSnippets(getTags());
		for (auto& def : scenarios) {
			if (all || hasExportSnippets(def->getTags())) {
				auto snippet = def->getSnippet();
				auto it = snippets.find(snippet);
				if (it != snippets.end()) snippets.erase(it);
				snippets.emplace(snippet, ScenarioRef(*this, *def));
			}
		}
	}

	void GherkinDocument::generate(const ScenarioMap& map)
	{
		try {
			if (background)
				background->generate(map, {});

			for (auto& def : scenarios)
				def->generate(map, {});
		}
		catch (const std::exception& e) {
			errors.emplace_back(e);
		}
	}

	bool GherkinDocument::isPrimitiveEscaping() const
	{
		return provider.primitiveEscaping;
	}

	const StringLines& GherkinDocument::getTags() const
	{
		static const StringLines empty;
		return feature ? feature->getTags() : empty;
	}

	JSON GherkinDocument::dump(const GherkinFilter& filter) const
	{
		JSON json;
		json["language"] = language;
		set(json, "filename", filepath.wstring());

		try {
			auto match = MatchType::Unknown;
			if (feature) {
				match = filter.match(feature->getTags());
				if (match == MatchType::Exclude)
					return JSON();
			}
			if (scenarios.empty()) {
				if (match == MatchType::Unknown)
					return JSON();
			}
			else {
				for (auto& scen : scenarios) {
					switch (filter.match(scen->getTags())) {
					case MatchType::Exclude:
						continue;
					case MatchType::Include:
						break;
					default:
						if (match == MatchType::Unknown)
							continue;
						else
							break;
					}
					json["scenarios"].push_back(*scen);
				}
				if (json["scenarios"].empty())
					return JSON();
			}
			set(json, "feature", feature);
			set(json, "background", background);
			set(json, "errors", errors);
		}
		catch (const std::exception& e) {
			json["errors"].push_back(
				JSON({ "text" }, e.what())
			);
		}
		return json;
	}

	GherkinDocument::operator JSON() const
	{
		GherkinFilter filter({});
		return dump(filter);
	}
}
