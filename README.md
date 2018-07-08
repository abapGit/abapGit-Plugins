[![abaplint](https://abaplint.org/badges/larshp/abapGit-Plugins)](http://abaplint.org/project/larshp/abapGit-Plugins)

# abapGit-Plugins
This repository contains plugins for abapGit to support other objecttypes. 
By inheriting from `zcl_abapgit_object`and implementing `zif_abapgit_plugin` you can create plugins for objecttypes which are not natively supported by ABAPGit yet.
However, please be aware that the format used by ABAPGit may change, so please check back frequently to make sure your plugin stays up-to-date.

# SOBJ-based generic plugin
One plugin already contained in this repository is a generic plugin supporting multiple object types. Similar to the SAP transport management system, it transports table content. As this is quite a dangerous operation (particularly when operating across systems with potentially different releases), you should check your systems technical components and the one from which you import the repository.

# abapGit-SAPLink-Bridge
abapGit allows easy syncing of Git-Repositories with ABAP packages.

However, the support for oject types is not yet as wide as the object-support by SAPLink. Thus, there is an adapter which wraps SAPLink-Plugins in order to use them with abapGit.
Since SAPLink has a more restrictive license compared to abapGit, you have to download the SAPLink-Bridge from [SAPLink Plug-ins](https://github.com/mrsimpson/SAPLink-Plugins). Check the prerequisites before you install!
