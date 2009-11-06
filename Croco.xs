#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libcroco/libcroco.h>

#include "const-c.inc"

MODULE = CSS::Croco		PACKAGE = CSS::Croco		PREFIX = cr_om_

CROMParser *
new (class)
    char* class
    CODE:
        CROMParser *parser = NULL;
        parser = cr_om_parser_new(NULL);
        if ( !parser ) {
            die("Could not create parser");
        }
        RETVAL = parser;
    OUTPUT:
        RETVAL

CRStyleSheet *
parse (parser, string)
    CROMParser *parser;
    char* string
    CODE:
        CRStyleSheet *stylesheet = NULL ;
        enum CRStatus status = cr_om_parser_parse_buf( parser, string, strlen( string ), CR_UTF_8, &stylesheet );
        if ( status == CR_OK ) {
            RETVAL = stylesheet;
        } else {
            die( "Died: %d", status ); 
        }
    OUTPUT:
        RETVAL
            
CRStyleSheet *
parse_file (parser, filename)
    CROMParser *parser;
    char* filename
    CODE:
        CRStyleSheet *stylesheet = NULL ;
        enum CRStatus status = cr_om_parser_parse_file( parser, filename, CR_UTF_8, &stylesheet );
        if ( status == CR_OK ) {
            RETVAL = stylesheet;
        } else {
            die( "Died: %d", status ); 
        }
    OUTPUT:
        RETVAL

void
DESTROY(parser)
    CROMParser * parser
    CODE:
        cr_om_parser_destroy( parser );

MODULE = CSS::Croco		PACKAGE = CSS::Croco::StyleSheet		PREFIX = cr_ss_

char*
to_string(stylesheet)
    CRStyleSheet * stylesheet
    CODE:
        RETVAL = cr_stylesheet_to_string( stylesheet );
    OUTPUT: 
        RETVAL

void
rules(stylesheet)
    CRStyleSheet * stylesheet
    CODE:
        int i;
        int number_of_rules = cr_stylesheet_nr_rules( stylesheet );
        EXTEND(SP, number_of_rules+1);
        for ( i = 0; i < number_of_rules; i++ ) {
            CRStatement* statement = cr_stylesheet_statement_get_from_list( stylesheet, i );
            SV* rv = newSV(0);
            SV* class = newSVpv("CSS::Croco::Statement::", strlen("CSS::Croco::Statement::"));
            switch ( statement->type ) {
                case AT_RULE_STMT:
                    sv_catpv( class, "AtRule");
                    break;
                case RULESET_STMT:    
                    sv_catpv(class, "RuleSet");
                    break;
                case AT_IMPORT_RULE_STMT:
                    sv_catpv(class, "Import");
                    break;
                case AT_MEDIA_RULE_STMT: 
                    sv_catpv(class, "Media");
                    break;
                case AT_PAGE_RULE_STMT: 
                    sv_catpv(class, "Page");
                    break;
                case AT_CHARSET_RULE_STMT: 
                    sv_catpv(class, "Charset");
                    break;
                case AT_FONT_FACE_RULE_STMT:
                    sv_catpv(class, "FontFace");
                    break;
                default:
                    sv_catpv(class, "Unknown");
            }
            sv_setref_pv(rv, SvPV_nolen(class), (void*) statement);
            ST(i) = rv;
        }
        XSRETURN( number_of_rules );

void
DESTROY(stylesheet)
    CRStyleSheet * stylesheet
    CODE:
        cr_stylesheet_destroy( stylesheet );

MODULE = CSS::Croco		PACKAGE = CSS::Croco::Statement		PREFIX = cr_stmt_

char*
to_string(statement, indent = 0)
    CRStatement * statement
    long indent
    CODE:
        RETVAL = cr_statement_to_string( statement, indent );
    OUTPUT: 
        RETVAL

void
DESTROY(statement)
    CRStatement * statement
    CODE:
        //if statement was created from stylesheet, all is ok, it will be destroyed. But if it was created by parse
        //method, exists a memory leak :-(

MODULE = CSS::Croco		PACKAGE = CSS::Croco::Statement::RuleSet		PREFIX = cr_stmt_

SV*
declarations(statement)
    CRStatement *statement
    CODE:
        CRDeclaration* decl = NULL;
        cr_statement_ruleset_get_declarations(statement, &decl);
        int gimme = GIMME_V;

        if ( gimme == G_ARRAY ) {
            SPAGAIN;
            AV* av = newAV();
            int i;
            int n = cr_declaration_nr_props(decl);
            EXTEND(SP, n);
            for ( i = 0; i < n; i++ ) {
                SV* rv = newSV(0);
                ST(i) = sv_2mortal(sv_setref_pv(rv, "CSS::Croco::Declaration", (void *) decl ) );
                decl = decl->next;
            }
            XSRETURN( n );
        } else {
            SV* rv = newSV(0);
            sv_setref_pv(rv, "CSS::Croco::DeclarationList", (void*) decl);
            RETVAL = rv;
        }
    OUTPUT: 
        RETVAL        


CRDeclaration *
parse_declaration( statement, string)
    CRStatement* statement
    char* string
    CODE:
        CRDeclaration* decl = NULL;
        decl = cr_declaration_parse_from_buf( statement, string, CR_UTF_8 );
        RETVAL = decl;
    OUTPUT:
        RETVAL

MODULE = CSS::Croco		PACKAGE = CSS::Croco::DeclarationList		PREFIX = cr_decl_list_

CRDeclaration*
next(declaration)
    CRDeclaration * declaration
    CODE:
        RETVAL = declaration;
    OUTPUT:
        RETVAL

SV *
parse( class, string)
    char* class
    char* string
    CODE:
        CRDeclaration* decl = NULL;
        decl = cr_declaration_parse_list_from_buf( string, CR_UTF_8 );
        SV* rv = newSV(0);
        sv_setref_pv(rv, class, (void*) decl);
        RETVAL = rv;
    OUTPUT:
        RETVAL
        
SV *
property( declaration, name)
    CRDeclaration* declaration
    char* name
    CODE:
        CRDeclaration* decl = cr_declaration_get_by_prop_name( declaration, name );
        SV* rv = newSV(0);
        sv_setref_pv(rv, "CSS::Croco::Declaration", (void*) decl);
        RETVAL = rv;
    OUTPUT:
        RETVAL

char*
to_string(declaration, indent = 0)
    CRDeclaration * declaration
    long indent
    CODE:
        RETVAL = cr_declaration_list_to_string( declaration, indent );
    OUTPUT: 
        RETVAL

void
DESTROY( declaration )
    CRDeclaration* declaration
    CODE:
//        TODO
//        cr_declaration_destroy( declaration );

MODULE = CSS::Croco		PACKAGE = CSS::Croco::Declaration   PREFIX = cr_decl_list_

char*
property(declaration, value = NULL)
    CRDeclaration * declaration
    char* value
    CODE:
        if ( value ) {
            declaration->property = cr_string_new_from_string( value );
        }
        RETVAL = cr_string_dup2(declaration->property);
    OUTPUT:        
        RETVAL

SV*
value(declaration, value = NULL)
    CRDeclaration * declaration
    CRTerm* value
    CODE:
        if ( value ) {
            declaration->value = value;
        }
        CRTerm* term = declaration->value;
        SV* rv = newSV(0);
        SV* class = newSVpv("CSS::Croco::Term", strlen("CSS::Croco::Term"));
        switch ( term->type ) {
            case TERM_NO_TYPE:
                break;
            case TERM_NUMBER:
                sv_catpv(class, "::Number");
                break;
            case TERM_FUNCTION:
                sv_catpv(class, "::Function");
                break;
            case TERM_STRING:
                sv_catpv(class, "::String");
                break;
            case TERM_IDENT:
                sv_catpv(class, "::Ident");
                break;
            case TERM_URI:
                sv_catpv(class, "::URI");
                break;
            case TERM_RGB:
                sv_catpv(class, "::RGB");
                break;
            case TERM_UNICODERANGE:
                sv_catpv(class, "::UnicodeRange");
                break;
            case TERM_HASH:
                sv_catpv(class, "::Hash");
                break;
            default:
                sv_catpv(class, "::Unknown");
        }
        sv_setref_pv(rv, SvPV_nolen(class), (void*) term);
        RETVAL = rv;
    OUTPUT:        
        RETVAL

bool
important(declaration, value = NULL )
    CRDeclaration * declaration
    SV* value
    CODE:
        if ( value ) {
            declaration->important = SvIV(value);
        }
        RETVAL = declaration->important;
    OUTPUT:        
        RETVAL

CRDeclaration*
next(declaration)
    CRDeclaration * declaration
    CODE:
        RETVAL = declaration->next;
    OUTPUT:
        RETVAL

CRDeclaration*
prev(declaration)
    CRDeclaration * declaration
    CODE:
        RETVAL = declaration->prev;
    OUTPUT:
        RETVAL

char*
to_string(declaration, indent = 0)
    CRDeclaration * declaration
    long indent
    CODE:
        RETVAL = cr_declaration_to_string( declaration, indent );
    OUTPUT: 
        RETVAL

MODULE = CSS::Croco		PACKAGE = CSS::Croco::Term   PREFIX = cr_term_

char* get(term)
    CRTerm * term
    CODE:
        RETVAL = cr_term_to_string( term );
    OUTPUT:
        RETVAL

char*
to_string(term)
    CRTerm * term
    CODE:
        RETVAL = cr_term_to_string( term );
    OUTPUT: 
        RETVAL

MODULE = CSS::Croco		PACKAGE = CSS::Croco::Term::Number   PREFIX = cr_term_number_


MODULE = CSS::Croco		PACKAGE = CSS::Croco::Term::URI   PREFIX = cr_term_number_

SV* get(term)
    CRTerm * term
    CODE:
        SV* rv;
        char* string = cr_string_peek_raw_str(term->content.str);
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("URI",0)));
        XPUSHs(sv_2mortal(newSVpv(string,0)));
        PUTBACK;
        int count = call_pv( "URI::new", G_SCALAR );

        SPAGAIN;
        
        if ( count != 1 )
            croak("Some shit happened");

        rv = POPs;
        SvREFCNT_inc(rv);
        PUTBACK;
        FREETMPS;
        LEAVE;
        RETVAL = rv;
    OUTPUT:
        RETVAL

INCLUDE: const-xs.inc
