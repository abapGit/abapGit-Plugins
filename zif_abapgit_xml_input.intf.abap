interface ZIF_ABAPGIT_XML_INPUT
  public .

*    Proxy for lcl_xml_input in ZABAPGIT
    METHODS:
      read
        IMPORTING iv_name TYPE clike
        CHANGING  cg_data TYPE any
        RAISING   zcx_abapgit_object,
      get_raw
        RETURNING VALUE(ri_raw) TYPE REF TO if_ixml_node.

endinterface.