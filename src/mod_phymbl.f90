! AeroBulk / 2019 / L. Brodeau
!
!***********************************************************************************
! MODULE that gathers a collection of usefull functions related to the physics /
! thermodynamics of air within the Marine Boundaty Layer
!***********************************************************************************
!
!   When using AeroBulk to produce scientific work, please acknowledge with the following paper:
!
!   Brodeau, L., B. Barnier, S. Gulev, and C. Woods, 2016: Climatologically
!   significant effects of some approximations in the bulk parameterizations of
!   turbulent air-sea fluxes. J. Phys. Oceanogr., doi:10.1175/JPO-D-16-0169.1.


MODULE mod_phymbl

   !!   virt_temp     : virtual (aka sensible) temperature (potential or absolute)
   !!   rho_air       : density of (moist) air (depends on T_air, q_air and SLP
   !!   visc_air      : kinematic viscosity (aka Nu_air) of air from temperature
   !!   L_vap         : latent heat of vaporization of water as a function of temperature
   !!   cp_air        : specific heat of (moist) air (depends spec. hum. q_air)
   !!   gamma_moist   : adiabatic lapse-rate of moist air
   !!   One_on_L      : 1. / ( Obukhov length )
   !!   Ri_bulk       : bulk Richardson number aka BRN
   !!   q_sat         : saturation humidity as a function of SLP and temperature
   !!   q_air_rh      : specific humidity as a function of RH (fraction, not %), t_air and SLP

   USE mod_const

   IMPLICIT NONE
   PRIVATE

   INTERFACE virt_temp
      MODULE PROCEDURE virt_temp_vctr, virt_temp_sclr
   END INTERFACE virt_temp

   INTERFACE visc_air
      MODULE PROCEDURE visc_air_vctr, visc_air_sclr
   END INTERFACE visc_air

   INTERFACE gamma_moist
      MODULE PROCEDURE gamma_moist_vctr, gamma_moist_sclr
   END INTERFACE gamma_moist

   INTERFACE e_sat
      MODULE PROCEDURE e_sat_vctr, e_sat_sclr
   END INTERFACE e_sat

   INTERFACE e_sat_ice
      MODULE PROCEDURE e_sat_ice_vctr, e_sat_ice_sclr
   END INTERFACE e_sat_ice

   INTERFACE Ri_bulk
      MODULE PROCEDURE Ri_bulk_vctr, Ri_bulk_sclr
   END INTERFACE Ri_bulk

   INTERFACE q_sat
      MODULE PROCEDURE q_sat_vctr, q_sat_sclr
   END INTERFACE q_sat

   INTERFACE L_vap
      MODULE PROCEDURE L_vap_vctr, L_vap_sclr
   END INTERFACE L_vap

   INTERFACE rho_air
      MODULE PROCEDURE rho_air_vctr, rho_air_sclr
   END INTERFACE rho_air

   INTERFACE cp_air
      MODULE PROCEDURE cp_air_vctr, cp_air_sclr
   END INTERFACE cp_air

   INTERFACE alpha_sw
      MODULE PROCEDURE alpha_sw_vctr, alpha_sw_sclr
   END INTERFACE alpha_sw

   INTERFACE bulk_formula
      MODULE PROCEDURE bulk_formula_vctr, bulk_formula_sclr
   END INTERFACE bulk_formula

   INTERFACE qlw_net
      MODULE PROCEDURE qlw_net_vctr, qlw_net_sclr
   END INTERFACE qlw_net


   PUBLIC virt_temp
   PUBLIC rho_air
   PUBLIC visc_air
   PUBLIC L_vap
   PUBLIC cp_air
   PUBLIC gamma_moist
   PUBLIC One_on_L
   PUBLIC Ri_bulk
   PUBLIC q_sat
   PUBLIC e_sat
   PUBLIC e_sat_ice
   PUBLIC e_air
   PUBLIC rh_air
   PUBLIC rho_air_adv
   PUBLIC dry_static_energy
   PUBLIC q_air_rh
   PUBLIC q_air_dp
   PUBLIC q_sat_crude
   PUBLIC update_qnsol_tau
   PUBLIC alpha_sw
   PUBLIC bulk_formula
   PUBLIC qlw_net

   REAL(wp), PARAMETER  :: &
      &      repsilon = 1.e-6

CONTAINS

   !===============================================================================================
   FUNCTION virt_temp_sclr( pta, pqa )
      !!------------------------------------------------------------------------
      !!
      !! Compute the (absolute/potential) VIRTUAL temperature, based on the
      !! (absolute/potential) temperature and specific humidity
      !!
      !! If input temperature is absolute then output virtual temperature is absolute
      !! If input temperature is potential then output virtual temperature is potential
      !!
      !! Author: L. Brodeau, June 2019 / AeroBulk
      !!         (https://github.com/brodeau/aerobulk/)
      !!------------------------------------------------------------------------
      REAL(wp)             :: virt_temp_sclr !: virtual temperature [K]
      REAL(wp), INTENT(in) :: pta       !: absolute or potential air temperature [K]
      REAL(wp), INTENT(in) :: pqa       !: specific humidity of air   [kg/kg]
      !!-------------------------------------------------------------------
      !
      virt_temp_sclr = pta * (1._wp + rctv0*pqa)
      !!
      !! This is exactly the same thing as:
      !! virt_temp_sclr = pta * ( pwa + reps0) / (reps0*(1.+pwa))
      !! with wpa (mixing ration) defined as : pwa = pqa/(1.-pqa)
      !
   END FUNCTION virt_temp_sclr
   !!
   FUNCTION virt_temp_vctr( pta, pqa )
      REAL(wp), DIMENSION(jpi,jpj)             :: virt_temp_vctr !: virtual temperature [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pta !: absolute or potential air temperature [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pqa !: specific humidity of air   [kg/kg]
      virt_temp_vctr(:,:) = pta(:,:) * (1._wp + rctv0*pqa(:,:))
   END FUNCTION virt_temp_vctr
   !===============================================================================================


   FUNCTION rho_air_vctr( ptak, pqa, pslp )
      !!-------------------------------------------------------------------------------
      !!                           ***  FUNCTION rho_air_vctr  ***
      !!
      !! ** Purpose : compute density of (moist) air using the eq. of state of the atmosphere
      !!
      !! ** Author: L. Brodeau, June 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!-------------------------------------------------------------------------------
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   ptak      ! air temperature             [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pqa       ! air specific humidity   [kg/kg]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pslp      ! pressure in                [Pa]
      REAL(wp), DIMENSION(jpi,jpj)             ::   rho_air_vctr   ! density of moist air   [kg/m^3]
      !!-------------------------------------------------------------------------------
      rho_air_vctr = MAX( pslp / (R_dry*ptak * ( 1._wp + rctv0*pqa )) , 0.8_wp )
   END FUNCTION rho_air_vctr

   FUNCTION rho_air_sclr( ptak, pqa, pslp )
      !!-------------------------------------------------------------------------------
      !!                           ***  FUNCTION rho_air_sclr  ***
      !!
      !! ** Purpose : compute density of (moist) air using the eq. of state of the atmosphere
      !!
      !! ** Author: L. Brodeau, June 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!-------------------------------------------------------------------------------
      REAL(wp), INTENT(in) :: ptak           ! air temperature             [K]
      REAL(wp), INTENT(in) :: pqa            ! air specific humidity   [kg/kg]
      REAL(wp), INTENT(in) :: pslp           ! pressure in                [Pa]
      REAL(wp)             :: rho_air_sclr   ! density of moist air   [kg/m^3]
      !!-------------------------------------------------------------------------------
      rho_air_sclr = MAX( pslp / (R_dry*ptak * ( 1._wp + rctv0*pqa )) , 0.8_wp )
   END FUNCTION rho_air_sclr




   FUNCTION visc_air_sclr(ptak)
      !!----------------------------------------------------------------------------------
      !! Air kinetic viscosity (m^2/s) given from air temperature in Kelvin
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp)             :: visc_air_sclr   ! kinetic viscosity (m^2/s)
      REAL(wp), INTENT(in) :: ptak       ! air temperature in (K)
      !
      REAL(wp) ::   ztc, ztc2   ! local scalar
      !!----------------------------------------------------------------------------------
      !
      ztc  = ptak - rt0   ! air temp, in deg. C
      ztc2 = ztc*ztc
      visc_air_sclr = 1.326e-5*(1. + 6.542E-3*ztc + 8.301e-6*ztc2 - 4.84e-9*ztc2*ztc)
      !
   END FUNCTION visc_air_sclr

   FUNCTION visc_air_vctr(ptak)
      REAL(wp), DIMENSION(jpi,jpj)             ::   visc_air_vctr   ! kinetic viscosity (m^2/s)
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   ptak       ! air temperature in (K)
      INTEGER  ::   ji, jj      ! dummy loop indices
      DO jj = 1, jpj
         DO ji = 1, jpi
            visc_air_vctr(ji,jj) = visc_air_sclr( ptak(ji,jj) )
         END DO
      END DO
   END FUNCTION visc_air_vctr


   FUNCTION L_vap_vctr( psst )
      !!---------------------------------------------------------------------------------
      !!                           ***  FUNCTION L_vap_vctr  ***
      !!
      !! ** Purpose : Compute the latent heat of vaporization of water from temperature
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp), DIMENSION(jpi,jpj)             ::   L_vap_vctr   ! latent heat of vaporization   [J/kg]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   psst   ! water temperature                [K]
      !!----------------------------------------------------------------------------------
      !
      L_vap_vctr = (  2.501_wp - 0.00237_wp * ( psst(:,:) - rt0)  ) * 1.e6_wp
      !
   END FUNCTION L_vap_vctr

   FUNCTION L_vap_sclr( psst )
      !!---------------------------------------------------------------------------------
      !!                           ***  FUNCTION L_vap_sclr  ***
      !!
      !! ** Purpose : Compute the latent heat of vaporization of water from temperature
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp)             ::   L_vap_sclr   ! latent heat of vaporization   [J/kg]
      REAL(wp), INTENT(in) ::   psst         ! water temperature                [K]
      !!----------------------------------------------------------------------------------
      !
      L_vap_sclr = (  2.501_wp - 0.00237_wp * ( psst - rt0)  ) * 1.e6_wp
      !
   END FUNCTION L_vap_sclr


   FUNCTION cp_air_vctr( pqa )
      !!-------------------------------------------------------------------------------
      !!                           ***  FUNCTION cp_air_vctr  ***
      !!
      !! ** Purpose : Compute specific heat (Cp) of moist air
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!-------------------------------------------------------------------------------
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pqa      ! air specific humidity         [kg/kg]
      REAL(wp), DIMENSION(jpi,jpj)             ::   cp_air_vctr   ! specific heat of moist air   [J/K/kg]
      !!-------------------------------------------------------------------------------
      cp_air_vctr = rCp_dry + rCp_vap * pqa
   END FUNCTION cp_air_vctr

   FUNCTION cp_air_sclr( pqa )
      !!-------------------------------------------------------------------------------
      !!                           ***  FUNCTION cp_air_sclr  ***
      !!
      !! ** Purpose : Compute specific heat (Cp) of moist air
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!-------------------------------------------------------------------------------
      REAL(wp), INTENT(in) :: pqa           ! air specific humidity         [kg/kg]
      REAL(wp)             :: cp_air_sclr   ! specific heat of moist air   [J/K/kg]
      !!-------------------------------------------------------------------------------
      cp_air_sclr = rCp_dry + rCp_vap * pqa
   END FUNCTION cp_air_sclr





   FUNCTION gamma_moist_vctr( ptak, pqa )
      !!----------------------------------------------------------------------------------
      !!                           ***  FUNCTION gamma_moist_vctr  ***
      !!
      !! ** Purpose : Compute the moist adiabatic lapse-rate.
      !!     => http://glossary.ametsoc.org/wiki/Moist-adiabatic_lapse_rate
      !!     => http://www.geog.ucsb.edu/~joel/g266_s10/lecture_notes/chapt03/oh10_3_01/oh10_3_01.html
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   ptak          ! air temperature       [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pqa           ! specific humidity [kg/kg]
      REAL(wp), DIMENSION(jpi,jpj)             ::   gamma_moist_vctr   ! moist adiabatic lapse-rate
      !
      INTEGER  ::   ji, jj         ! dummy loop indices
      !!----------------------------------------------------------------------------------
      DO jj = 1, jpj
         DO ji = 1, jpi
            gamma_moist_vctr(ji,jj) = gamma_moist_sclr( ptak(ji,jj), pqa(ji,jj) )
         END DO
      END DO
   END FUNCTION gamma_moist_vctr

   FUNCTION gamma_moist_sclr( ptak, pqa )
      !!----------------------------------------------------------------------------------
      !! ** Purpose : Compute the moist adiabatic lapse-rate.
      !!     => http://glossary.ametsoc.org/wiki/Moist-adiabatic_lapse_rate
      !!     => http://www.geog.ucsb.edu/~joel/g266_s10/lecture_notes/chapt03/oh10_3_01/oh10_3_01.html
      !!
      !! ** Author: L. Brodeau, June 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp)             :: gamma_moist_sclr
      REAL(wp), INTENT(in) :: ptak, pqa ! air temperature (K) and specific humidity (kg/kg)
      !
      REAL(wp) :: zta, zqa, zwa, ziRT, zLvap        ! local scalars
      !!----------------------------------------------------------------------------------
      zta = MAX( ptak,  180._wp) ! prevents screw-up over masked regions where field == 0.
      zqa = MAX( pqa,  1.E-6_wp) !    "                   "                     "
      !!
      zwa = zqa / (1._wp - zqa)   ! w is mixing ratio w = q/(1-q) | q = w/(1+w)
      ziRT = 1._wp / (R_dry*zta)    ! 1/RT
      zLvap = L_vap_sclr( ptak )
      !!
      gamma_moist_sclr = grav * ( 1._wp + zLvap*zwa*ziRT ) / ( rCp_dry + zLvap*zLvap*zwa*reps0*ziRT/zta )
      !!
   END FUNCTION gamma_moist_sclr


   FUNCTION One_on_L( ptha, pqa, pus, pts, pqs )
      !!------------------------------------------------------------------------
      !!
      !! Evaluates the 1./(Obukhov length) from air temperature,
      !! air specific humidity, and frictional scales u*, t* and q*
      !!
      !! Author: L. Brodeau, June 2019 / AeroBulk
      !!         (https://github.com/brodeau/aerobulk/)
      !!------------------------------------------------------------------------
      REAL(wp), DIMENSION(jpi,jpj)             :: One_on_L     !: 1./(Obukhov length) [m^-1]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: ptha         !: reference potential temperature of air [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pqa          !: reference specific humidity of air   [kg/kg]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pus          !: u*: friction velocity [m/s]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pts, pqs     !: \theta* and q* friction aka turb. scales for temp. and spec. hum.
      !
      INTEGER  ::   ji, jj         ! dummy loop indices
      REAL(wp) ::     zqa          ! local scalar
      !!-------------------------------------------------------------------
      !
      DO jj = 1, jpj
         DO ji = 1, jpi
            !
            zqa = (1._wp + rctv0*pqa(ji,jj))
            !
            ! The main concern is to know whether, the vertical turbulent flux of virtual temperature, < u' theta_v' > is estimated with:
            !  a/  -u* [ theta* (1 + 0.61 q) + 0.61 theta q* ] => this is the one that seems correct! chose this one!
            !                      or
            !  b/  -u* [ theta*              + 0.61 theta q* ]
            !
            One_on_L(ji,jj) = grav*vkarmn*( pts(ji,jj)*zqa + rctv0*ptha(ji,jj)*pqs(ji,jj) ) &
               &               / MAX( pus(ji,jj)*pus(ji,jj)*ptha(ji,jj)*zqa , 1.E-9_wp )
            !
         END DO
      END DO
      !
      One_on_L = SIGN( MIN(ABS(One_on_L),200._wp), One_on_L ) ! (prevent FPE from stupid values over masked regions...)
      !
   END FUNCTION One_on_L


   !===============================================================================================
   FUNCTION Ri_bulk_sclr( pz, psst, ptha, pssq, pqa, pub )
      !!----------------------------------------------------------------------------------
      !! Bulk Richardson number according to "wide-spread equation"...
      !!
      !! ** Author: L. Brodeau, June 2019 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp)             :: Ri_bulk_sclr
      REAL(wp), INTENT(in) :: pz    ! height above the sea (aka "delta z")  [m]
      REAL(wp), INTENT(in) :: psst  ! SST                                   [K]
      REAL(wp), INTENT(in) :: ptha  ! pot. air temp. at height "pz"         [K]
      REAL(wp), INTENT(in) :: pssq  ! 0.98*q_sat(SST)                   [kg/kg]
      REAL(wp), INTENT(in) :: pqa   ! air spec. hum. at height "pz"     [kg/kg]
      REAL(wp), INTENT(in) :: pub   ! bulk wind speed                     [m/s]
      REAL(wp) ::   zqa, zta, zgamma, zdth_v, ztv, zsstv  ! local scalars
      !!-------------------------------------------------------------------
      zqa = 0.5_wp*(pqa+pssq)                                        ! ~ mean q within the layer...
      zta = 0.5_wp*( psst + ptha - gamma_moist(ptha,zqa)*pz ) ! ~ mean absolute temperature of air within the layer
      zta = 0.5_wp*( psst + ptha - gamma_moist(zta,        zqa)*pz ) ! ~ mean absolute temperature of air within the layer
      zgamma =  gamma_moist(zta, zqa)                                              ! Adiabatic lapse-rate for moist air within the layer
      !
      zsstv = psst*(1._wp + rctv0*pssq) ! absolute==potential virtual SST (absolute==potential because z=0!)
      !
      zdth_v = ptha*(1._wp + rctv0*pqa) - zsstv ! air-sea delta of "virtual potential temperature"
      !
      ztv = 0.5_wp*( zsstv + (ptha - zgamma*pz)*(1._wp + rctv0*pqa) )  ! ~ mean absolute virtual temp. within the layer
      !
      Ri_bulk_sclr = grav*zdth_v*pz / ( ztv*pub*pub )                            ! the usual definition of Ri_bulk_sclr
      !
   END FUNCTION Ri_bulk_sclr
   !!
   FUNCTION Ri_bulk_vctr( pz, psst, ptha, pssq, pqa, pub )
      REAL(wp), DIMENSION(jpi,jpj)             :: Ri_bulk_vctr
      REAL(wp)                    , INTENT(in) :: pz    ! height above the sea (aka "delta z")  [m]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: psst  ! SST                                   [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: ptha  ! pot. air temp. at height "pz"         [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pssq  ! 0.98*q_sat(SST)                   [kg/kg]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pqa   ! air spec. hum. at height "pz"     [kg/kg]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pub   ! bulk wind speed                     [m/s]
      INTEGER  ::   ji, jj
      DO jj = 1, jpj
         DO ji = 1, jpi
            Ri_bulk_vctr(ji,jj) = Ri_bulk_sclr( pz, psst(ji,jj), ptha(ji,jj), pssq(ji,jj), pqa(ji,jj), pub(ji,jj) )
         END DO
      END DO
   END FUNCTION Ri_bulk_vctr
   !===============================================================================================

   !===============================================================================================
   FUNCTION e_sat_sclr( ptak )
      !!----------------------------------------------------------------------------------
      !!                   ***  FUNCTION e_sat_sclr  ***
      !!                  < SCALAR argument version >
      !! ** Purpose : water vapor at saturation in [Pa]
      !!              Based on accurate estimate by Goff, 1957
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!
      !!    Note: what rt0 should be here, is 273.16 (triple point of water) and not 273.15 like here
      !!----------------------------------------------------------------------------------
      REAL(wp)             ::   e_sat_sclr   ! water vapor at saturation   [kg/kg]
      REAL(wp), INTENT(in) ::   ptak    ! air temperature                  [K]
      REAL(wp) ::   zta, ztmp   ! local scalar
      !!----------------------------------------------------------------------------------
      zta = MAX( ptak , 180._wp )   ! air temp., prevents fpe0 errors dute to unrealistically low values over masked regions...
      ztmp = rt0 / zta
      !
      ! Vapour pressure at saturation [Pa] : WMO, (Goff, 1957)
      e_sat_sclr = 100.*( 10.**( 10.79574*(1. - ztmp) - 5.028*LOG10(zta/rt0)        &
         &    + 1.50475*10.**(-4)*(1. - 10.**(-8.2969*(zta/rt0 - 1.)) )  &
         &    + 0.42873*10.**(-3)*(10.**(4.76955*(1. - ztmp)) - 1.) + 0.78614) )
      !
   END FUNCTION e_sat_sclr
   !!
   FUNCTION e_sat_vctr(ptak)
      REAL(wp), DIMENSION(jpi,jpj)             :: e_sat_vctr !: vapour pressure at saturation  [Pa]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: ptak    !: temperature (K)
      INTEGER  ::   ji, jj         ! dummy loop indices
      DO jj = 1, jpj
         DO ji = 1, jpi
            e_sat_vctr(ji,jj) = e_sat_sclr(ptak(ji,jj))
         END DO
      END DO
   END FUNCTION e_sat_vctr
   !===============================================================================================



   !FUNCTION e_sat_buck(rT, slp)
   !   !!**************************************************
   !   !!  rT:     air temperature          [K]
   !   !! slp:     atmospheric pressure     [Pa]
   !   !! e_sat:  water vapor at saturation [Pa]
   !   !!
   !   !! Based on Buck' formula for saturation vapor pressure
   !   !! from Buck (1981), J. App. Meteor., 1527-1532.
   !   !!
   !   !! This version follows the saturation specific humidity computation in
   !   !! the COARE Fortran code v2.5b.  This results in an increase of ~5% in
   !   !! latent heat flux compared to the calculation with Teten's
   !   !!
   !   !!**************************************************
   !   REAL(wp), DIMENSION(jpi,jpj)             :: e_sat_buck !: vapour pressure at saturation [Pa]
   !   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: rT, &        !: temperature                   [K]
   !      &                                        slp          !: atmospheric pressure          [Pa]
   !   REAL(wp), DIMENSION(:,:), ALLOCATABLE :: ztmp
   !   ALLOCATE ( ztmp(jpi,jpj) )
   !   !! Achtung: originaly given with temperature in deg.C and pressure in
   !   !!          millibars! 1 mb = 100 Pa !!!
   !   ztmp(:,:) = rT(:,:) - rt0
   !   !! Buck 1981:
   !   !! Buck, A. L., New equations for computing vapor pressure and enhancement
   !   !! factor, J. Appl. Meteorol., 20, 1527-1532, 1981
   !   !e_sat_buck = 611.21 * EXP( 17.502*ztmp/(ztmp + 240.97) )
   !   !! Official COARE 3.0 code:
   !   e_sat_buck = 611.2*(1.0007 + 3.46e-8*slp) * EXP( 17.502*ztmp/(ztmp + 240.97) )
   !   !! Kara et al. 2000:
   !   !!e_sat_buck = 611.21*(1. + 3.46E-8*slp)*EXP( (17.5*ztmp)/(240.97 + ztmp) )
   !   DEALLOCATE ( ztmp )
   !END FUNCTION e_sat_buck









   FUNCTION e_air(q_air, slp)

      !!--------------------------------------------------------------------
      !!                  **** Function e_air ****
      !!
      !! Gives vapour pressure of air from pressure and specific humidity
      !!
      !!--------------------------------------------------------------------

      REAL(wp), DIMENSION(jpi,jpj)             ::    e_air      !: vapour pressure at saturation  [Pa]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::          &
         &                 q_air,   &  ! specific humidity of air      [kg/kg]
         &                 slp        ! atmospheric pressure          [Pa]

      REAL(wp), DIMENSION(:,:), ALLOCATABLE :: ee, e_old
      REAL :: diff

      ALLOCATE ( ee(jpi,jpj), e_old(jpi,jpj) )

      diff  = 1.
      e_old = q_air*slp/reps0

      DO WHILE ( diff > repsilon )
         ee = q_air/reps0*(slp - (1. - reps0)*e_old)
         diff  = SUM( abs( ee - e_old) )
         e_old = ee
      END DO

      e_air = ee

      DEALLOCATE ( ee, e_old )

   END FUNCTION e_air




   FUNCTION rh_air(q_air, t_air, slp)

      !! Relative humidity of air

      REAL(wp), DIMENSION(jpi,jpj)             :: rh_air  !: relative humidity [] (fraction!!!, not percent!)
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: &
         &                 q_air,   &     !: specific humidity of air      [kg/kg]
         &                 t_air,   &     !: air temperature               [K]
         &                 slp           !: atmospheric pressure          [Pa]

      rh_air = e_sat(t_air)
      rh_air = e_air(q_air,slp) / rh_air

   END FUNCTION rh_air


   FUNCTION q_air_rh(prha, ptak, pslp)
      !!----------------------------------------------------------------------------------
      !! Specific humidity of air out of Relative Humidity
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp), DIMENSION(jpi,jpj)             :: q_air_rh
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: prha        !: relative humidity      [fraction, not %!!!]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: ptak        !: air temperature        [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pslp        !: atmospheric pressure   [Pa]
      !
      INTEGER  ::   ji, jj      ! dummy loop indices
      REAL(wp) ::   ze      ! local scalar
      !!----------------------------------------------------------------------------------
      !
      DO jj = 1, jpj
         DO ji = 1, jpi
            ze = prha(ji,jj)*e_sat_sclr(ptak(ji,jj))
            q_air_rh(ji,jj) = ze*reps0/(pslp(ji,jj) - (1. - reps0)*ze)
         END DO
      END DO
      !
   END FUNCTION q_air_rh




   FUNCTION q_air_dp(da, slp)
      !!
      !! Air specific humidity from dew point temperature
      !!
      REAL(wp), DIMENSION(jpi,jpj) :: q_air_dp  !: kg/kg
      !!
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: &
         &     da,     &    !: dew-point temperature   [K]
         &     slp         !: atmospheric pressure    [Pa]
      !!
      q_air_dp = e_sat(da)*reps0/(slp - (1. - reps0)*e_sat(da))
      !!
   END FUNCTION q_air_dp







   FUNCTION rho_air_adv(zt, zq, zP)
      !!
      !! Advanced version, using TRUE virtual temperature
      !!
      REAL(wp), DIMENSION(jpi,jpj) :: rho_air_adv      !: density of air [kg/m^3]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::  &
         &      zt,       &     !: air temperature in (K)
         &      zq,       &     !: air spec. hum. (kg/kg)
         &      zP              !: pressure in       (Pa)
      !!
      REAL(wp), DIMENSION(jpi,jpj) :: ztv !: virtual temperature
      !!
      ztv = zt/(1. - e_air(zq, zP)/zP*(1. - reps0))
      !!
      rho_air_adv = zP/(R_dry*ztv)
      !!
   END FUNCTION rho_air_adv


   !===============================================================================================
   FUNCTION q_sat_sclr( pta, ppa,  l_ice )
      !!---------------------------------------------------------------------------------
      !!                           ***  FUNCTION q_sat_sclr  ***
      !!
      !! ** Purpose : Conputes specific humidity of air at saturation
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp) :: q_sat_sclr
      REAL(wp), INTENT(in) :: pta  !: absolute temperature of air [K]
      REAL(wp), INTENT(in) :: ppa  !: atmospheric pressure        [Pa]
      LOGICAL,  INTENT(in), OPTIONAL :: l_ice  !: we are above ice
      REAL(wp) :: ze_s
      LOGICAL  :: lice
      !!----------------------------------------------------------------------------------
      lice = .FALSE.
      IF ( PRESENT(l_ice) ) lice = l_ice
      IF ( lice ) THEN
         ze_s = e_sat_ice( pta )
      ELSE
         ze_s = e_sat( pta ) ! Vapour pressure at saturation (Goff) :
      END IF
      q_sat_sclr = reps0*ze_s/(ppa - (1._wp - reps0)*ze_s)
   END FUNCTION q_sat_sclr
   !!
   FUNCTION q_sat_vctr( pta, ppa,  l_ice )
      REAL(wp), DIMENSION(jpi,jpj) :: q_sat_vctr
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pta  !: absolute temperature of air [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: ppa  !: atmospheric pressure        [Pa]
      LOGICAL,  INTENT(in), OPTIONAL :: l_ice  !: we are above ice
      LOGICAL  :: lice
      INTEGER  :: ji, jj
      !!----------------------------------------------------------------------------------
      lice = .FALSE.
      IF ( PRESENT(l_ice) ) lice = l_ice
      DO jj = 1, jpj
         DO ji = 1, jpi
            q_sat_vctr(ji,jj) = q_sat_sclr( pta(ji,jj) , ppa(ji,jj), l_ice=lice )
         END DO
      END DO
   END FUNCTION q_sat_vctr
   !===============================================================================================


   FUNCTION e_sat_ice_sclr(ptak)
      !!---------------------------------------------------------------------------------
      !! Same as "e_sat" but over ice rather than water!
      !!---------------------------------------------------------------------------------
      REAL(wp)             :: e_sat_ice_sclr !: vapour pressure at saturation in presence of ice [Pa]
      REAL(wp), INTENT(in) :: ptak
      !!
      REAL(wp) :: zle, ztmp
      !!---------------------------------------------------------------------------------
      ztmp = 273.16_wp/ptak
      !!
      zle  = -9.09718_wp*(ztmp - 1._wp)  - 3.56654_wp*LOG10(ztmp)      &
         &   + 0.876793_wp*(1._wp - ptak/273.16_wp) + LOG10(6.1071_wp)
      !!
      e_sat_ice_sclr = 100._wp * 10._wp**zle
   END FUNCTION e_sat_ice_sclr
   !!
   FUNCTION e_sat_ice_vctr(ptak)
      !! Same as "e_sat" but over ice rather than water!
      REAL(wp), DIMENSION(jpi,jpj) :: e_sat_ice_vctr !: vapour pressure at saturation in presence of ice [Pa]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: ptak
      INTEGER  :: ji, jj
      !!----------------------------------------------------------------------------------
      DO jj = 1, jpj
         DO ji = 1, jpi
            e_sat_ice_vctr(ji,jj) = e_sat_ice_sclr( ptak(ji,jj) )
         END DO
      END DO
   END FUNCTION e_sat_ice_vctr




   FUNCTION q_sat_crude(temp, zrho)

      REAL(wp), DIMENSION(jpi,jpj)             :: q_sat_crude
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: &
         &       temp,   &  !: sea surface temperature  [K]
         &       zrho       !: air density         [kg/m^3]

      q_sat_crude = 640380._wp/zrho * exp(-5107.4_wp/temp)

   END FUNCTION q_sat_crude







   FUNCTION dry_static_energy( pz, pta, pqa )
      !!----------------------------------------------------------------------------------
      !! Dry static energy "s" (Eq. 3.5 IFS doc)
      !!
      !! ** Author: L. Brodeau, June 2019 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp), DIMENSION(jpi,jpj)             ::   dry_static_energy
      REAL(wp)                    , INTENT(in) ::   pz    ! height above the sea         [m]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pta   ! absolute air temp. at pz m   [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pqa   ! air spec. hum. at pz m   [kg/kg]
      !!----------------------------------------------------------------------------------
      dry_static_energy = grav*pz + cp_air(pqa)*pta
   END FUNCTION dry_static_energy



   SUBROUTINE UPDATE_QNSOL_TAU( pzu, pTs, pqs, pTa, pqa, pust, ptst, pqst, pwnd, pUb, pslp, prlw, &
      &                         pQns, pTau,  &
      &                         Qlat)
      !!----------------------------------------------------------------------------------
      !! Purpose: returns the non-solar heat flux to the ocean aka "Qlat + Qsen + Qlw"
      !!          and the module of the wind stress => pTau = Tau
      !! ** Author: L. Brodeau, Sept. 2019 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp),                     INTENT(in)  :: pzu  ! height above the sea-level where all this takes place (normally 10m)
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pTs  ! water temperature at the air-sea interface [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pqs  ! satur. spec. hum. at T=pTs   [kg/kg]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pTa  ! potential air temperature at z=pzu [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pqa  ! specific humidity at z=pzu [kg/kg]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pust ! u*
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: ptst ! t*
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pqst ! q*
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pwnd ! wind speed module at z=pzu [m/s]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pUb  ! bulk wind speed at z=pzu (inc. pot. effect of gustiness etc) [m/s]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pslp ! sea-level atmospheric pressure [Pa]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: prlw ! downwelling longwave radiative flux [W/m^2]
      !
      REAL(wp), DIMENSION(jpi,jpj), INTENT(out) :: pQns ! non-solar heat flux to the ocean aka "Qlat + Qsen + Qlw" [W/m^2]]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(out) :: pTau ! module of the wind stress [N/m^2]
      !
      REAL(wp), DIMENSION(jpi,jpj), OPTIONAL, INTENT(out) :: Qlat
      !
      REAL(wp) :: zdt, zdq, zCd, zCh, zCe, zz0, zQlat, zQsen, zQlw
      INTEGER  ::   ji, jj     ! dummy loop indices
      !!----------------------------------------------------------------------------------
      DO jj = 1, jpj
         DO ji = 1, jpi

            zdt = pTa(ji,jj) - pTs(ji,jj) ;  zdt = SIGN( MAX(ABS(zdt),1.E-6_wp), zdt )
            zdq = pqa(ji,jj) - pqs(ji,jj) ;  zdq = SIGN( MAX(ABS(zdq),1.E-9_wp), zdq )
            zz0 = pust(ji,jj)/pUb(ji,jj)
            zCd = zz0*zz0
            zCh = zz0*ptst(ji,jj)/zdt
            zCe = zz0*pqst(ji,jj)/zdq

            CALL BULK_FORMULA( pzu, pTs(ji,jj), pqs(ji,jj), pTa(ji,jj), pqa(ji,jj), zCd, zCh, zCe, &
               &              pwnd(ji,jj), pUb(ji,jj), pslp(ji,jj), &
               &              pTau(ji,jj), zQsen, zQlat )

            zQlw = qlw_net_sclr( prlw(ji,jj), pTs(ji,jj) ) ! Net longwave flux

            pQns(ji,jj) = zQlat + zQsen + zQlw

            IF ( PRESENT(Qlat) ) Qlat(ji,jj) = zQlat
         END DO
      END DO
   END SUBROUTINE UPDATE_QNSOL_TAU









   SUBROUTINE BULK_FORMULA_SCLR( pzu, pTs, pqs, pTa, pqa, pCd, pCh, pCe, pwnd, pUb, pslp, &
      &                                 pTau, pQsen, pQlat,  pEvap, prhoa,  l_ice )
      !!----------------------------------------------------------------------------------
      REAL(wp),                     INTENT(in)  :: pzu  ! height above the sea-level where all this takes place (normally 10m)
      REAL(wp), INTENT(in)  :: pTs  ! water temperature at the air-sea interface [K]
      REAL(wp), INTENT(in)  :: pqs  ! satur. spec. hum. at T=pTs   [kg/kg]
      REAL(wp), INTENT(in)  :: pTa  ! potential air temperature at z=pzu [K]
      REAL(wp), INTENT(in)  :: pqa  ! specific humidity at z=pzu [kg/kg]
      REAL(wp), INTENT(in)  :: pCd
      REAL(wp), INTENT(in)  :: pCh
      REAL(wp), INTENT(in)  :: pCe
      REAL(wp), INTENT(in)  :: pwnd ! wind speed module at z=pzu [m/s]
      REAL(wp), INTENT(in)  :: pUb  ! bulk wind speed at z=pzu (inc. pot. effect of gustiness etc) [m/s]
      REAL(wp), INTENT(in)  :: pslp ! sea-level atmospheric pressure [Pa]
      !!
      REAL(wp), INTENT(out) :: pTau  ! module of the wind stress [N/m^2]
      REAL(wp), INTENT(out) :: pQsen !  [W/m^2]
      REAL(wp), INTENT(out) :: pQlat !  [W/m^2]
      !!
      REAL(wp), INTENT(out), OPTIONAL :: pEvap ! Evaporation [kg/m^2/s]
      REAL(wp), INTENT(out), OPTIONAL :: prhoa ! Air density at z=pzu [kg/m^3]
      LOGICAL,  INTENT(in),  OPTIONAL :: l_ice  !: we are above ice
      !!
      REAL(wp) :: ztaa, zgamma, zrho, zUrho, zevap
      INTEGER  :: jq
      LOGICAL  :: lice
      !!----------------------------------------------------------------------------------
      lice = .FALSE.
      IF ( PRESENT(l_ice) ) lice = l_ice
      !!
      !! Need ztaa, absolute temperature at pzu (formula to estimate rho_air needs absolute temperature, not the potential temperature "pTa")
      ztaa = pTa ! first guess...
      DO jq = 1, 4
         zgamma = gamma_moist( 0.5*(ztaa+pTs) , pqa )
         ztaa = pTa - zgamma*pzu   ! Absolute temp. is slightly colder...
      END DO
      zrho = rho_air(ztaa, pqa, pslp)
      zrho = rho_air(ztaa, pqa, pslp-zrho*grav*pzu) ! taking into account that we are pzu m above the sea level where SLP is given!

      zUrho = pUb*MAX(zrho, 1._wp)     ! rho*U10

      pTau = zUrho * pCd * pwnd ! Wind stress module

      zevap = zUrho * pCe * (pqa - pqs)
      pQsen = zUrho * pCh * (pTa - pTs) * cp_air(pqa)

      IF ( lice) THEN
         pQlat =      rLsub * zevap
         IF ( PRESENT(pEvap) ) pEvap = MAX( -zevap , 0._wp )
      ELSE
         pQlat = L_vap(pTs) * zevap
         IF ( PRESENT(pEvap) ) pEvap = -zevap
      END IF

      IF ( PRESENT(prhoa) ) prhoa = zrho

   END SUBROUTINE BULK_FORMULA_SCLR
   !!
   SUBROUTINE BULK_FORMULA_VCTR( pzu, pTs, pqs, pTa, pqa, pCd, pCh, pCe, pwnd, pUb, pslp, &
      &                                 pTau, pQsen, pQlat,  pEvap, prhoa,  l_ice )
      !!----------------------------------------------------------------------------------
      REAL(wp),                     INTENT(in)  :: pzu  ! height above the sea-level where all this takes place (normally 10m)
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pTs  ! water temperature at the air-sea interface [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pqs  ! satur. spec. hum. at T=pTs   [kg/kg]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pTa  ! potential air temperature at z=pzu [K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pqa  ! specific humidity at z=pzu [kg/kg]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pCd
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pCh
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pCe
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pwnd ! wind speed module at z=pzu [m/s]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pUb  ! bulk wind speed at z=pzu (inc. pot. effect of gustiness etc) [m/s]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)  :: pslp ! sea-level atmospheric pressure [Pa]
      !!
      REAL(wp), DIMENSION(jpi,jpj), INTENT(out) :: pTau  ! module of the wind stress [N/m^2]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(out) :: pQsen !  [W/m^2]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(out) :: pQlat !  [W/m^2]
      !!
      REAL(wp), DIMENSION(jpi,jpj), INTENT(out), OPTIONAL :: pEvap ! Evaporation [kg/m^2/s]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(out), OPTIONAL :: prhoa ! Air density at z=pzu [kg/m^3]
      LOGICAL,  INTENT(in),  OPTIONAL :: l_ice  !: we are above ice
      !!
      REAL(wp) :: zevap, zrho
      LOGICAL  :: lice
      INTEGER  :: ji, jj
      !!----------------------------------------------------------------------------------
      lice = .FALSE.
      IF ( PRESENT(l_ice) ) lice = l_ice
      !!
      DO jj = 1, jpj
         DO ji = 1, jpi
            !!
            CALL BULK_FORMULA_SCLR( pzu,  pTs(ji,jj), pqs(ji,jj), pTa(ji,jj), pqa(ji,jj),  &
               &                    pCd(ji,jj), pCh(ji,jj), pCe(ji,jj), pwnd(ji,jj), pUb(ji,jj), &
               &                   pslp(ji,jj), pTau(ji,jj), pQsen(ji,jj), pQlat(ji,jj),  &
               & pEvap=zevap, prhoa=zrho, l_ice=lice )
            !!
            IF ( PRESENT(pEvap) ) pEvap(ji,jj) = zevap
            IF ( PRESENT(prhoa) ) prhoa(ji,jj) = zrho
         END DO
      END DO
   END SUBROUTINE BULK_FORMULA_VCTR



   FUNCTION alpha_sw_vctr( psst )
      !!---------------------------------------------------------------------------------
      !!                           ***  FUNCTION alpha_sw_vctr  ***
      !!
      !! ** Purpose : ROUGH estimate of the thermal expansion coefficient of sea-water at the surface (P =~ 1010 hpa)
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp), DIMENSION(jpi,jpj)             ::   alpha_sw_vctr   ! thermal expansion coefficient of sea-water [1/K]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   psst   ! water temperature                [K]
      !!----------------------------------------------------------------------------------
      alpha_sw_vctr = 2.1e-5_wp * MAX(psst(:,:)-rt0 + 3.2_wp, 0._wp)**0.79
   END FUNCTION alpha_sw_vctr

   FUNCTION alpha_sw_sclr( psst )
      !!---------------------------------------------------------------------------------
      !!                           ***  FUNCTION alpha_sw_sclr  ***
      !!
      !! ** Purpose : ROUGH estimate of the thermal expansion coefficient of sea-water at the surface (P =~ 1010 hpa)
      !!
      !! ** Author: L. Brodeau, june 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
      !!----------------------------------------------------------------------------------
      REAL(wp)             ::   alpha_sw_sclr   ! thermal expansion coefficient of sea-water [1/K]
      REAL(wp), INTENT(in) ::   psst   ! sea-water temperature                   [K]
      !!----------------------------------------------------------------------------------
      alpha_sw_sclr = 2.1e-5_wp * MAX(psst-rt0 + 3.2_wp, 0._wp)**0.79
   END FUNCTION alpha_sw_sclr


   !===============================================================================================
   FUNCTION qlw_net_sclr( pdwlw, pts,  l_ice )
      !!---------------------------------------------------------------------------------
      !!                           ***  FUNCTION qlw_net_sclr  ***
      !!
      !! ** Purpose : Estimate of the net longwave flux at the surface
      !!----------------------------------------------------------------------------------
      REAL(wp) :: qlw_net_sclr
      REAL(wp), INTENT(in) :: pdwlw !: downwelling longwave (aka infrared, aka thermal) radiation [W/m^2]
      REAL(wp), INTENT(in) :: pts   !: surface temperature [K]
      LOGICAL,  INTENT(in), OPTIONAL :: l_ice  !: we are above ice
      REAL(wp) :: zemiss, zt2
      LOGICAL  :: lice
      !!----------------------------------------------------------------------------------
      lice = .FALSE.
      IF ( PRESENT(l_ice) ) lice = l_ice
      IF ( lice ) THEN
         zemiss = emiss_i
      ELSE
         zemiss = emiss_w
      END IF
      zt2 = pts*pts
      qlw_net_sclr = zemiss*( pdwlw - stefan*zt2*zt2)  ! zemiss used both as the IR albedo and IR emissivity...
   END FUNCTION qlw_net_sclr
   !!
   FUNCTION qlw_net_vctr( pdwlw, pts,  l_ice )
      REAL(wp), DIMENSION(jpi,jpj) :: qlw_net_vctr
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pdwlw !: downwelling longwave (aka infrared, aka thermal) radiation [W/m^2]
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pts   !: surface temperature [K]
      LOGICAL,  INTENT(in), OPTIONAL :: l_ice  !: we are above ice
      LOGICAL  :: lice
      INTEGER  :: ji, jj
      !!----------------------------------------------------------------------------------
      lice = .FALSE.
      IF ( PRESENT(l_ice) ) lice = l_ice
      DO jj = 1, jpj
         DO ji = 1, jpi
            qlw_net_vctr(ji,jj) = qlw_net_sclr( pdwlw(ji,jj) , pts(ji,jj), l_ice=lice )
         END DO
      END DO
   END FUNCTION qlw_net_vctr
   !===============================================================================================


   


END MODULE mod_phymbl





!FUNCTION Ri_bulk_ecmwf( pz, ptha, pdt, pqa, pdq, pub )
!   !!----------------------------------------------------------------------------------
!   !! Bulk Richardson number (Eq. 3.25 IFS doc)
!   !!
!   !! ** Author: L. Brodeau, June 2016 / AeroBulk (https://github.com/brodeau/aerobulk/)
!   !!----------------------------------------------------------------------------------
!   REAL(wp), DIMENSION(jpi,jpj) ::   Ri_bulk_ecmwf   !
!   REAL(wp)                    , INTENT(in) ::   pz    ! height above the sea        [m]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   ptha  ! pot. air temp. at height "pz"    [K]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pdt   ! ptha - sst                   [K]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pqa   ! air spec. hum. at pz m  [kg/kg]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pdq   ! pqa - ssq               [kg/kg]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pub   ! bulk wind speed           [m/s]
!   !!----------------------------------------------------------------------------------
!   !
!   Ri_bulk_ecmwf =   grav*pz/(pub*pub)   &
!      &            * ( pdt/(ptha - 0.5_wp*(pdt + grav*pz/cp_air(pqa))) + rctv0*pdq )
!   !
!END FUNCTION Ri_bulk_ecmwf

!FUNCTION Ri_bulk_ecmwf_b( pz, psst, ptha, pssq, pqa, pub )
!   !!----------------------------------------------------------------------------------
!   !! TODO: Bulk Richardson number according to equation 3.90 (p.50) of IFS Cy45r1 doc!
!   !!
!   !! ** Author: L. Brodeau, June 2019 / AeroBulk (https://github.com/brodeau/aerobulk/)
!   !!----------------------------------------------------------------------------------
!   REAL(wp), DIMENSION(jpi,jpj)             :: Ri_bulk_ecmwf_b
!   REAL(wp)                    , INTENT(in) :: pz    ! height above the sea (aka "delta z")  [m]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: psst  ! SST                                   [K]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: ptha  ! pot. air temp. at height "pz"         [K]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pssq  ! 0.98*q_sat(SST)                   [kg/kg]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pqa   ! air spec. hum. at height "pz"     [kg/kg]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) :: pub   ! (scalar) bulk wind speed            [m/s]
!   !
!   INTEGER  ::   ji, jj         ! dummy loop indices
!   REAL(wp) :: zta, zsz, zs0, zqa         ! local scalar
!   !!-------------------------------------------------------------------
!   !
!   DO jj = 1, jpj
!      DO ji = 1, jpi
!         zqa = 0.5_wp*(pqa(ji,jj)+pssq(ji,jj))  ! ~ mean q in layer...
!         zta = 0.5_wp*( psst(ji,jj) + ptha(ji,jj) - gamma_moist(ptha(ji,jj),zqa)*pz ) ! Absolute temperature of air within the layer
!         zta = 0.5_wp*( psst(ji,jj) + ptha(ji,jj) - gamma_moist(zta,        zqa)*pz ) ! Absolute temperature of air within the layer
!         zta = 0.5_wp*( psst(ji,jj) + ptha(ji,jj) - gamma_moist(zta,        zqa)*pz ) ! Absolute temperature of air within the layer
!         !
!         zs0 =           (rCp_dry + rCp_vap*pssq(ji,jj))*psst(ji,jj)  ! dry static energy at air-sea interface (z=0)
!         zsz = grav*pz + (rCp_dry + rCp_vap* pqa(ji,jj))*zta          ! dry static energy at z=pz
!         !
!         Ri_bulk_ecmwf_b(ji,jj) =   grav*pz/(pub(ji,jj)*pub(ji,jj)) &
!            &  * ( 2._wp*(zsz - zs0)/(zsz + zs0 - grav*pz) + rctv0*(pqa(ji,jj) - pssq(ji,jj)) )
!         !
!      END DO
!   END DO
!   !
!END FUNCTION Ri_bulk_ecmwf_b

!FUNCTION Ri_bulk_coare( pz, ptha, pdt, pdq, pub )
!   !!----------------------------------------------------------------------------------
!   !! Bulk Richardson number as found in the original coare 3.0 algorithm...
!   !!----------------------------------------------------------------------------------
!   REAL(wp), DIMENSION(jpi,jpj) ::   Ri_bulk_coare   !
!   REAL(wp)                    , INTENT(in) ::   pz    ! height above the sea        [m]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   ptha   ! air temperature at pz m     [K]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pdt   ! ptha - sst                   [K]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pdq   ! pqa - ssq               [kg/kg]
!   REAL(wp), DIMENSION(jpi,jpj), INTENT(in) ::   pub   ! bulk wind speed           [m/s]
!   !!----------------------------------------------------------------------------------
!   Ri_bulk_coare = grav*pz*(pdt + rctv0*ptha*pdq)/(ptha*pub*pub)  !! Ribu Bulk Richardson number ;       !Ribcu = -zu/(zi0*0.004*Beta0**3) !! Saturation Rib, zi0 = tropicalbound. layer depth
!END FUNCTION Ri_bulk_coare


