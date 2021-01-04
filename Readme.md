# **Platform Runtime Mechanism**

Platform Runtime Mechanism (PRM) introduces the capability of moving platform-specific code out of SMM and into a
code module that executes within the OS context. Moving this firmware to the OS context provides better transparency
and mitigates the negative system impact currently accompanied with SMM solutions. Futhermore, the PRM code is
packaged into modules with well-defined entry points, each representing a specific PRM functionality.

The `PrmPkg` maintained in this branch provides a single cohesive set of generic PRM functionality that is intended
to be leveraged by platform firmware with minimal overhead to integrate PRM functionality in the firmware.

## **IMPORTANT NOTE**
> The code provided  in this package and branch are for proof-of-concept purposes only. The code does not represent a
formal design and is not validated at product quality. The development of this feature is shared in the edk2-staging
branch to simplify collaboration by allowing direct code contributions and early feedback throughout its development.

## Overview
At a high-level, PRM can be viewed from three levels of granularity:

1. PRM interface - Encompassing the entirety of firmware functionalities and data provided to OS runtime. Most
   information is provided through ACPI tables to be agnostic to a UEFI implementation.
2. PRM module - An independently updatable package of PRM handlers. The PRM interface will be composed of multiple
   PRM modules. This requirement allows for the separation of OEM and IHV PRM code, each of which can be serviced
   independently.
3. PRM handler - The implementation/callback of a single PRM functionality as identified by a GUID.

## Firmware Design
The firmware has three key generic drivers to support PRM:

1. A PRM Loader driver - Functionality is split across three phases:
   1. Discover - Find all PRM modules in the firmware image made available by the platform firmware author.
      * This phase includes verifying authenticity/integrity of the image, the image executable type, the export
        table is present and the PRM Export Module Descriptor is present and valid.
   2. Process - Convert PRM handler GUID to name mappings in the PRM Module Export Descriptor to PRM handler Name
      to physical address mappings required to construct the PRM ACPI table.
   3. Publish - Publish the PRM ACPI table using the information from the Process phase.

2. A PRM Configuration driver - A generic driver responsible for processing PRM module configuration information
   consumed through a `PRM_CONFIG_PROTOCOL` per PRM module instance. Therefore, the `PRM_CONFIG_PROTOCOL` serves
   as the dynamic interface for this driver to process PRM module resources and prepare the module's data to be
   configured properly for OS runtime.

3. A PRM Module - Not a single driver but a user written PE/COFF image that follows the PRM module authoring process.
   A PRM module groups together cohesive sets of PRM functionality into functions referred to as "PRM handlers".

## PRM Module

By default, the EDK II implementation of UEFI does not allow images with the subsystem type
IMAGE_SUBSYSTEM_EFI_RUNTIME_DRIVER to be built with exports. 

```
ERROR - Linker #1294 from LINK : fatal exports and import libraries are not supported with /SUBSYSTEM:EFI_RUNTIME_DRIVER
```
This can adjusted in the MSVC linker options.

__For the purposes of this POC__, the subsystem type is changed in the firmware build to allow the export table to be
added but the subsystem type in the final image is still 0xC (EFI Runtime Driver). This is important to allow the DXE
dispatcher to use its standard image verification and loading algorithms to load the image into permanent memory during
the DXE execution phase.

All firmware-loaded PRM modules are loaded into a memory buffer of type EfiRuntimeServicesCode. This means the
operating system must preserve all PRM handler code and the buffer will be reflected in the UEFI memory map. The
execution for invoking PRM handlers is the same as that required for UEFI Runtime Services, notably 4KiB or more of
available stack space must be provided and the stack must be 16-byte aligned. 

__*Note:*__ Long term it is possible to similarly load the modules into a EfiRuntimeServicesCode buffer and perform
relocation fixups with a new EFI module type for PRM if desired. It was simply not done since it is not essential
for this POC.

Where possible, PRM module information is stored and generated using industry compiler tool chains. This is a key
motivation behind using PE/COFF export tables to expose PRM module information and using a single PRM module binary
definition consistent between firmware and OS load.

### PRM Module Exports
A PRM module must contain at least three exports: A PRM Module Export Descriptor, a PRM Module Update Lock Descriptor,
and at least one PRM handler. Here's an example of an export table from a PRM module that has a single PRM handler:

```
  0000000000005000: 00 00 00 00 FF FF FF FF 00 00 00 00 46 50 00 00  ....ÿÿÿÿ....FP..
  0000000000005010: 01 00 00 00 03 00 00 00 03 00 00 00 28 50 00 00  ............(P..
  0000000000005020: 34 50 00 00 40 50 00 00 78 13 00 00 30 40 00 00  4P..@P..x...0@..
  0000000000005030: 20 40 00 00 67 50 00 00 86 50 00 00 A0 50 00 00   @..gP...P...P..
  0000000000005040: 00 00 01 00 02 00 50 72 6D 53 61 6D 70 6C 65 43  ......PrmSampleC
  0000000000005050: 6F 6E 74 65 78 74 42 75 66 66 65 72 4D 6F 64 75  ontextBufferModu
  0000000000005060: 6C 65 2E 64 6C 6C 00 44 75 6D 70 53 74 61 74 69  le.dll.DumpStati
  0000000000005070: 63 44 61 74 61 42 75 66 66 65 72 50 72 6D 48 61  cDataBufferPrmHa
  0000000000005080: 6E 64 6C 65 72 00 50 72 6D 4D 6F 64 75 6C 65 45  ndler.PrmModuleE
  0000000000005090: 78 70 6F 72 74 44 65 73 63 72 69 70 74 6F 72 00  xportDescriptor.
  00000000000050A0: 50 72 6D 4D 6F 64 75 6C 65 55 70 64 61 74 65 4C  PrmModuleUpdateL
  00000000000050B0: 6F 63 6B 00                                      ock.

    00000000 characteristics
    FFFFFFFF time date stamp
        0.10 version
           1 ordinal base
           3 number of functions
           3 number of names

    ordinal hint RVA      name
          1    0 00001378 DumpStaticDataBufferPrmHandler
          2    1 00004030 PrmModuleExportDescriptor
          3    2 00004020 PrmModuleUpdateLock
```
### PRM Image Format
PRM modules are ultimately PE/COFF images. However, when packaged in firmware the PE/COFF image is placed into a
Firmware File System (FFS) file. This is transparent to the operating system but done to better align with the typical
packaging of PE32(+) images managed in the firmware binary image. In the dump of the PRM FV binary image shown earlier,
the FFS sections placed by EDK II build tools ("DXE dependency", "User interface", "Version") that reside alongside the
PE/COFF binary are shown. A PRM module can be placed into a firmware image as a pre-built PE/COFF binary or built
during the firmware build process. In either case, the PE/COFF section is contained in a FFS file as shown in that
image.

### PRM Module Implementation
To simplify building the PRM Module Export Descriptor, a PRM module implementation can use the following macros to mark
functions as PRM handlers. In this example, a PRM module registers three functions by name as PRM handlers with the
associated GUIDs.

```
//
// Register the PRM export information for this PRM Module
//
PRM_MODULE_EXPORT (
  PRM_HANDLER_EXPORT_ENTRY (PRM_HANDLER_1_GUID, PrmHandler1),
  PRM_HANDLER_EXPORT_ENTRY (PRM_HANDLER_2_GUID, PrmHandler2),
  PRM_HANDLER_EXPORT_ENTRY (PRM_HANDLER_N_GUID, PrmHandlerN)
  );
```

`PRM_MODULE_EXPORT` take a variable-length argument list of `PRM_HANDLER_EXPORT_ENTRY` entries that each describe an
individual PRM handler being exported for the module. Ultimately, this information is used to define the structure
necessary to statically allocate the PRM Module Export Descriptor Structure (and its PRM Handler Export Descriptor
substructures) in the image.

Another required export for PRM modules is automatically provided in `PrmModule.h`, a header file that pulls together
all the includes needed to author a PRM module. This export is `PRM_MODULE_UPDATE_LOCK_EXPORT`. By including,
`PrmModule.h`, a PRM module has the `PRM_MODULE_UPDATE_LOCK_DESCRIPTOR` automatically exported.

## PRM Handler Constraints
At this time, PRM handlers are restricted to a maximum identifier length of 128 characters. This is checked when using
the `PRM_HANDLER_EXPORT` macro by using a static assert that reports a violation at build-time.

PRM handlers are **not** allowed to use UEFI Runtime Services and should not rely upon any UEFI constructs. For the
purposes of this POC, this is currently not explicitly enforced but should be in the final changes.
