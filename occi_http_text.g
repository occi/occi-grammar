grammar occi_http_text;

//TODO: So the generated lexer and parser are useable by all languages and to not be dependant on embedded target code (e.g. actions)
//      the parser should return well-formed json which can be deserialised by most languages.

//Caveat! JSON strings are created via concatenation. This is not efficent. If you want more efficency, modify the
//        grammar so that it utilises more direct means of in-memory/domain specific model creation.

options {
  //Change me: if you want a different targetted language for the parser/lexer generation
  //Values: {ActionScript, C, CPP, CSharp2, CSharp3, Java, Delphi, JavaScript, ObjC, Perl5, Ruby, Python}
  language = Java;
}

tokens{
  //OCCI header names
  CATEGORY_HEADER = 'Category:';
  LINK_HEADER = 'Link:';
  ATTR_HEADER = 'X-OCCI-Attribute:';
  LOCATION_HEADER = 'X-OCCI-Location:';

  //Category attribute names
  SCHEME_ATTR = 'scheme';
  CLASS_ATTR = 'class';
  TITLE_ATTR = 'title';
  REL_ATTR = 'rel';
  LOCATION_ATTR = 'location';
  ATTRIBUTES_ATTR = 'attributes';
  ACTION_ATTR = 'actions';

  //Link attribute names
  SELF_ATTR = 'self';
  CAT_ATTR = 'category';

  //General tokens
  CAT_ATTR_SEP = ';';
  VAL_ASSIGN = '=';
  QUOTE = '"';
  OPEN_PATH = '<';
  CLOSE_PATH = '>';
  COMMA = ',';
}

//Change me: @header contains target language specific decls
@header {
  package be.edmonds.occi;
}

//Change me: @lexer::header contains target language specific decls
@lexer::header {
  package be.edmonds.occi;
}

// ----------------------------------------
// ---------- All OCCI Headers ------------
// ----------------------------------------

occi_header:
  (
  //Nice-to-have: merge these 2 rules
    multiple_category_header
  | category_header

  //Nice-to-have: merge these 2 rules
  | multiple_link_header
  | link_header

  | attribute_header

  | location_header
  )+
  EOF
;

// ----------------------------------------
// ----------- Category Header ------------
// ----------------------------------------
/*
ABNF representation of category from the http rendering specification

  Category         = "Category" ":" #category-value [ "," #category-value]
  category-value   = term
                    ";" "scheme" "=" <"> scheme <">
                    ";" "class" "=" ( class | <"> class <"> )
                    [ ";" "title" "=" quoted-string ]
                    [ ";" "rel" "=" <"> type-identifier <"> ]
                    [ ";" "location" "=" URI ]
                    [ ";" "attributes" "=" <"> attribute-list <"> ]
                    [ ";" "actions" "=" <"> action-list <"> ]
  term             = token
  scheme           = URI
  type-identifier  = scheme term
  class            = "action" | "mixin" | "kind"
  attribute-list   = attribute-name
                   | attribute-name *( 1*SP attribute-name)
  attribute-name   = attr-component *( "." attr-component )
  attr-component   = LOALPHA *( LOALPHA | DIGIT | "-" | "_" )
  action-list      = action
                   | action *( 1*SP action)
  action           = type-identifier

Examples:

  Category: storage;
      scheme="http://schemas.ogf.org/occi/infrastructure#";
      class="kind";
      title="Storage Resource";
      rel="http://schemas.ogf.org/occi/core#resource";
      location=/storage/;
      attributes="occi.storage.size occi.storage.state";
      actions="http://schemas.ogf.org/occi/infrastructure/storage/action#resize ...";
*/
multiple_category_header returns [String category]
  : CATEGORY_HEADER multi_cat1 = category_header_val
    {$category = "["+$multi_cat1.category;}
    (
      COMMA multi_cat2 = category_header_val
      {$category += ", "+$multi_cat2.category;}
    )+
    {$category += "]";}
;
category_header returns [String category]
  : CATEGORY_HEADER category_header_val
    {$category = "{\"category\":{" + $category_header_val.category + "}}"; }
;
category_header_val returns [String category]
  : term_attr scheme_attr class_attr (title_attr | rel_attr | location_attr | cat_attributes_attr | action_attr)*
    {
      $category =
      "\"term\":\"" + $term_attr.term + "\", " +
      "\"scheme\":\"" + $scheme_attr.scheme + "\", " +
      "\"class\":\"" + $class_attr.klass + "\", " +
      "\"title\":\"" + $title_attr.title + "\", "+
      "\"rel\":\"" + $rel_attr.rel + "\", "+
      "\"location\":\"" + $location_attr.location + "\"," +
      "\"attributes\":[" + $cat_attributes_attr.attributes + "], " +
      "\"actions\":[" + $action_attr.actions + "]"
    ;}
;
term_attr returns[String term]
  : TOKEN
    {$term = $TOKEN.text;}
;

scheme_attr returns[String scheme]
  : CAT_ATTR_SEP SCHEME_ATTR VAL_ASSIGN QUOTE scheme_val QUOTE
    {$scheme = $scheme_val.uri;}
;
scheme_val returns[String uri]
  : URI
    {$uri = $URI.text;}
;

class_attr returns[String klass]
  : CAT_ATTR_SEP CLASS_ATTR VAL_ASSIGN QUOTE class_val QUOTE
    {$klass = $class_val.klass;}
;
class_val returns[String klass]
  : CLASS
    {$klass = $CLASS.text;}
;

title_attr returns[String title]
  : CAT_ATTR_SEP TITLE_ATTR VAL_ASSIGN QUOTE title_val QUOTE
    {$title = $title_val.title;}
;
title_val returns[String title]
  : TOKEN
    {$title = $TOKEN.text;}
;

rel_attr returns[String rel]
  : CAT_ATTR_SEP REL_ATTR VAL_ASSIGN QUOTE rel_val QUOTE
    {$rel = $rel_val.rel;}
;
rel_val returns[String rel]
  : TOKEN
    {$rel = $TOKEN.text;}
;

location_attr returns[String location]
  : CAT_ATTR_SEP LOCATION_ATTR VAL_ASSIGN QUOTE location_val QUOTE
    {$location = $location_val.location;}

;
location_val returns[String location]
  : TOKEN
    {$location = $TOKEN.text;}
;

cat_attributes_attr returns[String attributes]
  : CAT_ATTR_SEP ATTRIBUTES_ATTR VAL_ASSIGN QUOTE attributes_names QUOTE
  {$attributes = $attributes_names.attributes;}
;
attributes_names returns[String attributes]
  : single_attr = attribute_attr_name
    {$attributes = "\"" + $single_attr.attribute_name + "\"";}

  | {$attributes="";}
    multi_attr1 = attribute_attr_name
    {$attributes = "\"" + $multi_attr1.attribute_name + "\"";}

    ( multi_attr2 = attribute_attr_name
      {$attributes += ", \"" + $multi_attr2.attribute_name + "\"";}
    )+
;
action_attr returns [String actions]
  : CAT_ATTR_SEP ACTION_ATTR VAL_ASSIGN QUOTE action_val QUOTE
    {$actions = $action_val.actions;}
;
action_val returns [String actions]
  : single_attr = action_uri
    {$actions = "\"" + $single_attr.action + "\"";}
  | multi_attr1 = action_uri {$actions = "\"" + $multi_attr1.action + "\"";}
    (
      multi_attr2 = action_uri {$actions += ", \"" + $multi_attr2.action + "\"";}
    )+

;
action_uri returns [String action]
  : URI
    {$action = $URI.text;}
;
// ----------------------------------------
// -------------- Link Header -------------
// ----------------------------------------
/*
ABNF representation of category from the http rendering specification

Link specification for links in general:

  Link             = "Link" ":" #link-value
  link-value       = "<" URI-Reference ">"
                    ";" "rel" "=" <"> resource-type <">
                    [ ";" "self" "=" <"> link-instance <"> ]
                    [ ";" "category" "=" link-type ]
                    *( ";" link-attribute )
  term             = token
  scheme           = URI
  type-identifier  = scheme term
  resource-type    = type-identifier *( 1*SP type-identifier )
  link-type        = type-identifier *( 1*SP type-identifier )
  link-instance    = URI-reference
  link-attribute   = attribute-name "=" ( token | quoted-string )
  attribute-name   = attr-component *( "." attr-component )
  attr-component   = LOALPHA *( LOALPHA | DIGIT | "-" | "_" )

Link specification for links that call actions:

  Link             = "Link" ":" #link-value
  link-value       = "<" action-uri ">"
                    ";" "rel" "=" <"> action-type <">
  term             = token
  scheme           = URI
  type-identifier  = scheme term
  action-type      = type-identifier
  action-uri       = URL "?" "action=" term
*/
//TODO action links spec to output JSON
//TODO allow for 2 forms of Link headers
//TODO allow for multiple links per line seperated by ','
multiple_link_header
  : 'link TODO'
;
link_header
  : LINK_HEADER  link_header_val
;
link_header_val
  : link_path_attr rel_attr (self_attr | link_category_attr)* link_attributes_attr?
;
link_path_attr:
  OPEN_PATH link_path_val CLOSE_PATH
;
link_path_val:
  PATH
;

self_attr:
  CAT_ATTR_SEP SELF_ATTR VAL_ASSIGN QUOTE self_val QUOTE
;
self_val:
  TOKEN
;

link_category_attr:
  CAT_ATTR_SEP CAT_ATTR VAL_ASSIGN QUOTE link_category_val QUOTE
;
link_category_val:
  TOKEN
;

link_attributes_attr:
  (CAT_ATTR_SEP attribute_attr)+
;
attribute_attr:
  attribute_attr_name VAL_ASSIGN attribute_attr_val
;
attribute_attr_name returns[String attribute_name]
  : ATTRIB_NAME
  {$attribute_name = $ATTRIB_NAME.text;}
;
attribute_attr_val:
  (QUOTE attribute_attr_string_val QUOTE) | attribute_attr_int_val
;
attribute_attr_string_val:
  TOKEN
;
attribute_attr_int_val:
  DIGIT
;


// ----------------------------------------
// -------- X-OCCI-Attribute Header--------
// ----------------------------------------
/*

ABNF representation of X-OCCI-Attribute from the http rendering specification

  Attribute        = "X-OCCI-Attribute" ":" #attribute-repr
  attribute-repr   = attribute-name "=" ( token | quoted-string )
  attribute-name   = attr-component *( "." attr-component )
  attr-component   = LOALPHA *( LOALPHA | DIGIT | "-" | "_" )

Example:
  X-OCCI-Attribute: occi.compute.architechture="x86_64"
  X-OCCI-Attribute: occi.compute.architechture="x86_64", occi.compute.cores=2
*/
//TODO output attribute header as JSON
attribute_header:
  ATTR_HEADER attribute_attrs
;
attribute_attrs:
  attribute_attr (COMMA attribute_attr)*
;

// ----------------------------------------
// ------- X-OCCI-Location Header ---------
// ----------------------------------------
/*

ABNF representation of X-OCCI-Location from the http rendering specification

  Location        = "X-OCCI-Location" ":" location-value
  location-value  = URI-reference

Examples:
  X-OCCI-Location: http://example.com/compute/123
  X-OCCI-Location: http://example.com/compute/123, http://example.com/compute/123
*/
//TODO output location header as JSON
location_header:
  LOCATION_HEADER location_paths
;
location_paths:
  location_path (COMMA location_path)*
;
location_path:
  PATH
;

//TODO many of these lexical rules need to be more accurate
ATTRIB_NAME: ('a'..'z' | 'A'..'Z')('a'..'z' | 'A'..'Z' | DIGIT)+ ('.') TOKEN;
PATH: ('/' TOKEN) ('/' TOKEN)*;
CLASS: ('kind'|'mixin'|'action');
URI: ('http://' | 'https://') TOKEN;
TOKEN: ('a'..'z' | 'A'..'Z') ('a'..'z' | 'A'..'Z')*;
DIGIT: '0'..'9'+;
WS: (' ' | '\t' | '\n' | '\r'){$channel = HIDDEN;};