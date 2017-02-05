CLASS zcx_abapgit_object DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA mv_text TYPE string.

    METHODS constructor
      IMPORTING
        !iv_text  TYPE string OPTIONAL
        !previous LIKE previous OPTIONAL .

    METHODS get_text REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCX_ABAPGIT_OBJECT IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.

    mv_text = iv_text.
  ENDMETHOD.


  METHOD get_text.
    IF mv_text IS NOT INITIAL.
      result = mv_text.
    ELSE.
      super->get_text( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
