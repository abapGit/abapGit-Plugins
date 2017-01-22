INTERFACE zif_abapgit_plugin PUBLIC.

  TYPES: BEGIN OF ty_metadata,
           class        TYPE string,
           version      TYPE string,
           late_deser   TYPE string,
           delete_tadir TYPE abap_bool,
         END OF ty_metadata.

  METHODS serialize
    IMPORTING io_xml TYPE REF TO zif_abapgit_xml_output
    RAISING   zcx_abapgit_object.

  METHODS deserialize
    IMPORTING iv_package TYPE devclass
              io_xml     TYPE REF TO zif_abapgit_xml_input
    RAISING   zcx_abapgit_object.

  METHODS delete RAISING zcx_abapgit_object.

  METHODS exists
    RETURNING
      VALUE(rv_bool) TYPE abap_bool.

  METHODS jump.

  METHODS get_metadata
    RETURNING VALUE(rs_metadata) TYPE ty_metadata.
ENDINTERFACE.
