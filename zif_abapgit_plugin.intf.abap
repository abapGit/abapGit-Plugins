INTERFACE zif_abapgit_plugin
  PUBLIC .

  TYPES: BEGIN OF ty_metadata,
           BEGIN OF serializer,
             class   TYPE string,
             version TYPE string,
           END OF serializer,
           master_language LIKE sy-langu,
         END OF ty_metadata.

  METHODS serialize RAISING zcx_abapgit_object.

  METHODS deserialize
    IMPORTING
              !iv_package TYPE devclass
    RAISING   zcx_abapgit_object.

  METHODS delete RAISING zcx_abapgit_object.

  METHODS exists
    RETURNING
      VALUE(rv_bool) TYPE abap_bool .

  METHODS jump .

  METHODS get_metadata
    RETURNING VALUE(rs_metadata) TYPE ty_metadata.
ENDINTERFACE.