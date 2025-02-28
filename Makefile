# AeroBulk / 2015 / L. Brodeau
# https://github.com/brodeau/aerobulk/

include make.macro

All: lib/libaerobulk.a bin/aerobulk_toy.x bin/example_call_aerobulk.x bin/test_aerobulk_ice.x  bin/test_aerobulk_oce+ice.x 

test: All bin/test_aerobulk_buoy_series_oce.x bin/test_aerobulk_buoy_series_ice.x bin/test_phymbl.x bin/test_cx_vs_wind.x bin/test_ice.x \
      bin/test_aerobulk_cdnf_series.x bin/test_psi_stab.x bin/test_coef_n10.x

CPP: lib/libaerobulk_cxx.a bin/example_call_aerobulk_cxx.x
cpp: CPP


# 
# bin/test_coef_no98.x

#-L$(DIR_FORT_LIB) $(LNK_FORT_LIB)

LIB = -L./lib -laerobulk 

LIB_SRC = src/mod_const.f90 \
	  src/mod_phymbl.f90 \
          src/mod_skin_coare.f90 \
          src/mod_skin_ecmwf.f90 \
	  src/mod_common_coare.f90 \
	  src/mod_blk_coare3p0.f90 \
	  src/mod_blk_coare3p6.f90 \
          src/mod_blk_ncar.f90 \
	  src/mod_blk_ecmwf.f90 \
          src/mod_blk_andreas.f90 \
	  src/mod_blk_neutral_10m.f90 \
          src/mod_aerobulk_compute.f90 \
          src/mod_aerobulk.f90 \
	  src/ice/mod_cdn_form_ice.f90 \
	  src/ice/mod_blk_ice_nemo.f90 \
	  src/ice/mod_blk_ice_an05.f90 \
	  src/ice/mod_blk_ice_lu12.f90 \
	  src/ice/mod_blk_ice_lg15.f90 src/ice/mod_blk_ice_lg15_io.f90 \
	  src/ice/mod_blk_ice_best.f90


LIB_OBJ = $(LIB_SRC:.f90=.o)

#LIB_OBO = $(LIB_SRC:.f90=.o)
#LIB_OBJ = $(patsubst src%,obj%,$(LIB_OBO))

LIB_COMP = -L$(DIR_FORT_LIB) $(LNK_FORT_LIB)

LIB_CXX = -L./lib -laerobulk_cxx -L$(DIR_FORT_LIB) $(LNK_FORT_LIB)

LIB_SRC_CXX = src/aerobulk.cpp \
		  src/mod_aerobulk_cxx.f90

LIB_OBJ_CXX = src/aerobulk.o \
		  src/mod_aerobulk_cxx.o


CXXFLAGS += -I./include

.SUFFIXES: 
.SUFFIXES: .f90 .o .cpp

lib/libaerobulk.a: $(LIB_OBJ)
	@echo ""
	@mkdir -p lib
	ar -rv lib/libaerobulk.a  $(LIB_OBJ)
	ranlib lib/libaerobulk.a
	@echo ""

lib/libaerobulk_cxx.a: $(LIB_OBJ) $(LIB_OBJ_CXX)
	@echo ""
	@mkdir -p lib
	ar -rv lib/libaerobulk_cxx.a $(LIB_OBJ_CXX)
	ranlib lib/libaerobulk_cxx.a
	@echo ""

bin/aerobulk_toy.x: src/tests/aerobulk_toy.f90 lib/libaerobulk.a
	@mkdir -p bin
	$(FC) $(FF) src/tests/aerobulk_toy.f90 -o bin/aerobulk_toy.x $(LIB)

bin/example_call_aerobulk.x: src/tests/example_call_aerobulk.f90 lib/libaerobulk.a
	@mkdir -p bin
	$(FC) $(FF) src/tests/example_call_aerobulk.f90 -o bin/example_call_aerobulk.x $(LIB)

bin/test_coef_n10.x: src/tests/test_coef_n10.f90 lib/libaerobulk.a
	@mkdir -p bin
	$(FC) $(FF) src/tests/test_coef_n10.f90 -o bin/test_coef_n10.x $(LIB)

bin/test_coef_no98.x: src/tests/test_coef_no98.f90 lib/libaerobulk.a
	@mkdir -p bin
	$(FC) $(FF) src/tests/test_coef_no98.f90 -o bin/test_coef_no98.x $(LIB)

bin/test_phymbl.x: src/tests/test_phymbl.f90 lib/libaerobulk.a
	@mkdir -p bin
	$(FC) $(FF) src/tests/test_phymbl.f90 -o bin/test_phymbl.x $(LIB)

bin/test_cx_vs_wind.x: src/tests/test_cx_vs_wind.f90 lib/libaerobulk.a
	@mkdir -p bin dat
	$(FC) $(FF) src/tests/test_cx_vs_wind.f90 -o bin/test_cx_vs_wind.x $(LIB)

bin/test_ice.x: src/ice/test_ice.f90 lib/libaerobulk.a
	@mkdir -p bin
	$(FC) $(FF) src/ice/test_ice.f90 -o bin/test_ice.x $(LIB)

bin/test_aerobulk_ice.x: src/ice/test_aerobulk_ice.f90 lib/libaerobulk.a
	@mkdir -p bin
	$(FC) $(FF) src/ice/test_aerobulk_ice.f90 -o bin/test_aerobulk_ice.x $(LIB)

bin/test_aerobulk_oce+ice.x: src/ice/test_aerobulk_oce+ice.f90 lib/libaerobulk.a
	@mkdir -p bin
	$(FC) $(FF) src/ice/test_aerobulk_oce+ice.f90 -o bin/test_aerobulk_oce+ice.x $(LIB)





bin/example_call_aerobulk_cxx.x: src/tests/example_call_aerobulk.cpp lib/libaerobulk.a lib/libaerobulk_cxx.a
	@mkdir -p bin dat
	$(CXX) $(CXXFLAGS) src/tests/example_call_aerobulk.cpp -o bin/example_call_aerobulk_cxx.x $(LIB_CXX) $(LIB) $(LIB_COMP)

bin/test_aerobulk_buoy_series_oce.x: src/tests/test_aerobulk_buoy_series_oce.f90 lib/libaerobulk.a mod/io_ezcdf.mod
	@mkdir -p bin
	$(FC) $(FF) src/io_ezcdf.o src/tests/test_aerobulk_buoy_series_oce.f90 -o bin/test_aerobulk_buoy_series_oce.x $(LIB) -L$(NETCDF_DIR)/lib $(L_NCDF)

bin/test_aerobulk_buoy_series_ice.x: src/ice/test_aerobulk_buoy_series_ice.f90 lib/libaerobulk.a mod/io_ezcdf.mod
	@mkdir -p bin
	$(FC) $(FF) src/io_ezcdf.o src/ice/test_aerobulk_buoy_series_ice.f90 -o bin/test_aerobulk_buoy_series_ice.x $(LIB) -L$(NETCDF_DIR)/lib $(L_NCDF)

bin/test_aerobulk_cdnf_series.x: src/ice/test_aerobulk_cdnf_series.f90 lib/libaerobulk.a mod/io_ezcdf.mod
	@mkdir -p bin
	$(FC) $(FF) src/io_ezcdf.o src/ice/test_aerobulk_cdnf_series.f90 -o bin/test_aerobulk_cdnf_series.x $(LIB) -L$(NETCDF_DIR)/lib $(L_NCDF)

bin/test_psi_stab.x: src/tests/test_psi_stab.f90 lib/libaerobulk.a mod/io_ezcdf.mod
	@mkdir -p bin
	$(FC) $(FF) src/io_ezcdf.o src/tests/test_psi_stab.f90 -o bin/test_psi_stab.x $(LIB) -L$(NETCDF_DIR)/lib $(L_NCDF)





mod/io_ezcdf.mod: src/io_ezcdf.f90
	@mkdir -p mod
	$(FC) $(FF) -I$(NETCDF_DIR)/include -c src/io_ezcdf.f90 -o src/io_ezcdf.o



.f90.o: $(LIB_SRC) $(LIB_SRC_CXX)
	@mkdir -p mod
	$(FC) -c $(FF) $(FORT_INC) $< -o $*.o

.cpp.o: $(LIB_SRC_CXX)
	@mkdir -p mod
	$(CXX) -c $(CXXFLAGS) $< -o $*.o

clean:
	rm -rf obj mod bin lib src/*.o src/ice/*.o *~ \#* dat *.svg *.png *.eps *.gp *.out *.nc *.dat *.done *.err

distclean: clean
	rm -f *.svg *.png *.eps *.gp *.out *.nc *.dat
	rm -rf figures
#/*.x  *.log *~ out  mod/* lib/* *.nc tmp.* \#* *.info  config.dat *.tmp
