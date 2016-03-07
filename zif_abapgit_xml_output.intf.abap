interface ZIF_ABAPGIT_XML_OUTPUT
  public .

*    Proxy for lcl_xml_output in ZABAPGIT
    METHODS:
      add
        IMPORTING iv_name TYPE clike
                  ig_data TYPE any
        RAISING   zcx_abapgit_object,
      set_raw
        IMPORTING ii_raw TYPE REF TO if_ixml_element,
      render
        IMPORTING iv_normalize  TYPE sap_bool DEFAULT abap_true
                  is_metadata   TYPE zcl_abapgit_object=>ty_metadata
        RETURNING VALUE(rv_xml) TYPE string.

endinterface.