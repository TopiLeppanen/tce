noinst_LTLIBRARIES = libcdg.la
libcdg_la_SOURCES = ControlDependenceNode.cc ControlDependenceEdge.cc ControlDependenceGraph.cc

SRC_ROOT_DIR = $(top_srcdir)/src
BASE_DIR = ${SRC_ROOT_DIR}/base
APPLIBS_DIR = ${SRC_ROOT_DIR}/applibs
TOOLS_DIR = ${SRC_ROOT_DIR}/tools
POM_DIR = ${BASE_DIR}/program
TPEF_DIR = ${BASE_DIR}/tpef
OSAL_DIR = ${BASE_DIR}/osal
MACH_DIR = ${BASE_DIR}/mach
UM_DIR = ${BASE_DIR}/umach
GRAPH_DIR = ${BASE_DIR}/Graph
DISASSEMBLER_DIR = ${APPLIBS_DIR}/Disassembler
SCHEDULER_DIR = ${APPLIBS_DIR}/Scheduler/
PR_DIR = ${SCHEDULER_DIR}/ProgramRepresentations/
DDG_DIR = ${PR_DIR}/DDG/
PDG_DIR = ${PR_DIR}/PDG/
CFLOWGRAPH_DIR = ${PR_DIR}/CFG
IBUFFER_DIR = ${APPLIBS_DIR}/InstructionBuffer

AM_CPPFLAGS = -I${TOOLS_DIR} -I${POM_DIR} -I${TPEF_DIR} -I${OSAL_DIR} \
	-I${MACH_DIR} -I${UM_DIR} -I${GRAPH_DIR} -I${DISASSEMBLER_DIR} \
	-I${CFLOWGRAPH_DIR} -I${PDG_DIR} -I${DDG_DIR} ${LLVM_CPPFLAGS} \
	-I${IBUFFER_DIR}

dist-hook:
	rm -rf $(distdir)/CVS $(distdir)/.deps $(distdir)/Makefile

MAINTAINERCLEANFILES = *~ *.gcov *.bbg *.bb *.da




## headers start
libcdg_la_SOURCES += \
	ControlDependenceGraph.hh ControlDependenceNode.hh \
	ControlDependenceEdge.hh 
## headers end
