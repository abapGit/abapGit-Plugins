class ZCL_ABAPGIT_OBJECT_IWPR definition
  public
  inheriting from ZCL_ABAPGIT_OBJECT
  final
  create public .

public section.

  interfaces ZIF_ABAPGIT_PLUGIN .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ABAPGIT_OBJECT_IWPR IMPLEMENTATION.


METHOD zif_abapgit_plugin~delete.

* todo, add IWPR handling code here

ENDMETHOD.


METHOD zif_abapgit_plugin~deserialize.

  mo_files->read_xml( ).

ENDMETHOD.


METHOD zif_abapgit_plugin~exists.

* todo

ENDMETHOD.


METHOD zif_abapgit_plugin~jump.

  WRITE: / 'jump to', mv_obj_name.

ENDMETHOD.


METHOD zif_abapgit_plugin~serialize.

  mo_files->add_xml( ).

ENDMETHOD.
ENDCLASS.