noinst_LTLIBRARIES = libselector.la
libselector_la_SOURCES = MoveNodeGroup.cc ScopeSelector.cc \
	SchedulingScope.cc BasicBlockSelector.cc MoveNodeSelector.cc \
	SequentialMoveNodeSelector.cc MoveNodeGroupBuilder.cc \
        BUMoveNodeSelector.cc

SRC_ROOT_DIR = $(top_srcdir)/src
BASE_DIR = ${SRC_ROOT_DIR}/base
APPLIBS_DIR = ${SRC_ROOT_DIR}/applibs
TOOLS_DIR = ${SRC_ROOT_DIR}/tools
POM_DIR = ${BASE_DIR}/program
TPEF_DIR = ${BASE_DIR}/tpef
OSAL_DIR = ${BASE_DIR}/osal
MACH_DIR = ${BASE_DIR}/mach
UM_DIR = ${BASE_DIR}/umach
SCHED_APPLIBS_DIR = ${APPLIBS_DIR}/Scheduler
RESOURCE_MODEL_DIR = ${APPLIBS_DIR}/Scheduler/ResourceModel
PDG_DIR = ${APPLIBS_DIR}/Scheduler/ProgramRepresentations/PDG
CFG_DIR = ${APPLIBS_DIR}/Scheduler/ProgramRepresentations/CFG
DDG_DIR = ${APPLIBS_DIR}/Scheduler/ProgramRepresentations/DDG
GRAPH_DIR = ${BASE_DIR}/Graph
DISASM_DIR = ${APPLIBS_DIR}/Disassembler


AM_CPPFLAGS = -I${RESOURCE_MODEL_DIR} -I${PDG_DIR} -I${TOOLS_DIR} -I${POM_DIR} \
	-I${OSAL_DIR} -I${MACH_DIR} -I${GRAPH_DIR} -I${SCHED_APPLIBS_DIR} \
	-I${CFG_DIR} -I${DDG_DIR} -I${DISASM_DIR} ${LLVM_CPPFLAGS}

dist-hook:
	rm -rf $(distdir)/CVS $(distdir)/.deps $(distdir)/Makefile

MAINTAINERCLEANFILES = *~ *.gcov *.bbg *.bb *.da

## headers start
libselector_la_SOURCES += \
	CriticalPathBBMoveNodeSelector.hh MoveNodeSelector.hh \
	MoveNodeGroupBuilder.hh MoveNodeGroup.hh \
	SequentialMoveNodeSelector.hh BUMoveNodeSelector.hh \
	ReadyMoveNodeGroupList.hh
## headers end
