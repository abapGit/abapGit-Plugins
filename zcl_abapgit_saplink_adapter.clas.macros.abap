*"* use this source file for any macro definitions you need
*"* in the implementation part of the class
  DEFINE check_valid_saplink.
    if mo_saplink is INITIAL.
      raise EXCEPTION type zcx_abapgit_object
        EXPORTING
          iv_text = |No valid saplink-implementation found - class { mv_saplink_classname } cannot be instantiated|.
    endif.
  END-OF-DEFINITION.