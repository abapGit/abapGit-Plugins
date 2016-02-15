# abapGit-Plugins
This repository contains plugins for ABAPGit to support other objecttypes.
Most prominently, it contains a generic implementation wrapping SAPLink-Plugins.

# ABAPGit-SAPLink-Bridge
ABAPGit allows easy syncing of Git-Repositories with ABAP packages. 
However, the support for oject types is not yet as wide as the object-support by SAPLink.
Thus,  an adapter which wraps SAPLink-Plugins in order to use them with ABAPGit is included.
As this one references ZSAPLINK, installation of SAPLink is a pre-requisite before being able 
to successfully compile this repository.
