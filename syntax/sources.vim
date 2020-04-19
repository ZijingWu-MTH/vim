syntax keyword Identifier PASS0_BINPLACE PASS1_BINPLACE PASS2_BINPLACE PASS3_BINPLACE
syntax keyword Identifier TARGETNAME DLLENTRY BUILD_PRODUCES BUILD_CONSUMES
syntax keyword Identifier NTTARGETFILE0 NTTARGETFILE1 NTTARGETFILES SOURCES DIRS PASS0_BINPLACE
syntax keyword Identifier USER_CS_FLAGS LINKER_FLAGS C_DEFINES MSBUILD_FLAGS
syntax keyword Identifier TARGETTYPE MANAGED_CODE PASS1_LINK PASS2_LINK UNSAFE_CODE
syntax keyword Identifier REFERENCES DYNLINK CULTURES INCLUDES UMTYPE MANAGED_PLATFORM_SPECIFIC
syntax keyword Keyword console windows NOTARGET 
syntax keyword Keyword FO_FO CS_CZ DA_DK DE_DE EL_GR ES_ES FI_FI FR_FR HU_HU IT_IT JA_JP KO_KR NB_NO NL_NL PL_PL PT_BR RO_RO RU_RU SV_SE ZH_CN ZH_TW EN_US

syntax match Error "\S\s\+$"hs=s+1  
syntax match Identifier "\$(\(WIN64\|VERSIONINFO_INC_PATH\|CLR_REF_PATH\|SDXROOT\|OBJ_PATH\|_LCSROOT\|_NTTREE\|O\))"
syntax match Identifier "\$(\(USER_CS_FLAGS\|LINKER_FLAGS\|C_DEFINES\|MSBUILD_FLAGS\))"
syntax match Comment "#.*$"
syntax match Include "^\s*!INCLUDE"
syntax match Keyword "^\s*!\(ifndef\|if\|else\|endif\|undef\|UNDEF\|IF\|ENDIF\)"
