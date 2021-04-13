!===============================================================================
!> @file user.f90
!> @brief User-specified initial and boundary conditions
!> @author Juan C. Toledo
!> @date 20/May/2013
 
! Copyright (c) 2014 Juan C. Toledo and Alejandro Esquivel
!
! This file is part of Walicxe3D.
!
! Walicxe3D is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see http://www.gnu.org/licenses/.

!===============================================================================

module userconds
! ============================================
!< @brief User-specified initial and boundary conditions
!< @details This is the file where the user sets the initial conditions of
!! the simulation, as well as any special boundary conditions or custom
!! modifications to the simulation.
!!
!! How to use this module:
!!   1) Add "use" statements to include any modules you require in the
!!      section marked [1].
!!   2) You can define aditional module-wide global variables and parameters
!!      in the section marked [2].
!!   3) Fill in the subroutine userInitialCondition(), marked [3], which
!!      is called at the beginning of the simulation.
!!   4) Optionally, fill in the subroutine userBoundary(), marked [4],
!!      which is called at the end of each boundary exchange operation.
!!
!! All subroutines in this module automatically have access to the global
!! parameters and variables.
! ============================================

  use parameters
  use globals
  ! ============================================
  ! [1] Add HERE any aditional modules required by your simulation

  ! > YOUR MODULES HERE >
  use winds
  use orbits

  ! ============================================
  implicit none

  ! ============================================
  ! [2] Define HERE any additional parameters or variables required
  ! by the user subroutines below if they they are not provided by
  ! an external module
  ! > YOUR ADDITIONAL PARAMETERS HERE <
  
  type(spherical_wind_type) :: wind1
  type(spherical_wind_type) :: wind2
  
  
  ! Initial position of the wind 1 source
  real :: x1 
  real :: y1 
  real :: z1 = zphystot/2

  ! Initial position of the wind 2 source
  real :: x2 
  real :: y2 
  real :: z2 = zphystot/2

  ! Initial velocity of the wind 1 source
  real :: vx1 
  real :: vy1 
  real :: vz1 

  ! Initial velocity of the wind 2 source
  real :: vx2 
  real :: vy2 
  real :: vz2 
  
  ! 0   periastron : maximum approach point
  ! 0.5 Apoastron  : maximum departure point
  real :: phase 



  ! ============================================

contains

  subroutine userInitialCondition (uvars)
  ! ============================================
  ! [3] USER-DEFINED INITIAL CONDITIONS
  !
  !< @brief User-defined Initial Conditions
  !< @details This subroutine is called at the beginning of the simulation,
  !! after the base grid is built and a basic uniform initial condition
  !! is imposed. It is to be modified by the user to define the problem-
  !! specific Initial Condition.
  !!
  !! IMPORTANT: This subroutine receives the FLOW variables array to be 
  !! modified as argument 'uvars'. The subroutine must modify this array,
  !! *NOT* the global arrays U, UP or PRIMS.
  !!
  !! The array has the following structure:
  !!   uvars ( block ID, equation number, cell_i, cell_j, cell_k )
  !! where the equation numbering is:
  !!   1: rho
  !!   2: rho*u
  !!   3: rho*v
  !!   4: rho*w
  !!   5: E (kinetic+thermal)
  !! If the passive magnetic field is enabled:
  !!   6: B_x
  !!   7: B_y
  !!   8: B_z
  !! If passive scalars are enabled, they begin after all other flow
  !! variables (i.e., 9+ if passive B-field enabled, 6+ if not).
  !!
  !! Note that the cell indices include ghost cells. For instance, if we
  !! had a 1-deep ghost cell layer then cells from 1 to ncells_x would be
  !! physical cells, while cells 0 and ncells_x+1  would be ghost cells.
  ! ============================================

    implicit none
    real, intent(inout) :: uvars (nbMaxProc, neqtot, &
                           nxmin:nxmax, nymin:nymax, nzmin:nzmax)

    ! ============================================
    ! > YOUR INITIAL CONDITIONS CODE HERE <

    call computeBinary(phase, x1, y1, x2, y2, vx1, vy1, vx2, vy2)

    ! The spherical wind parameters of wind WC7
    wind1%xc = x1 
    wind1%yc = y1 
    wind1%zc = z1
    wind1%radius = 2.0 * AU
    wind1%mdot = 4.5e-7 * MSUN/YR
    wind1%vinf = 1000 * KPS
    wind1%temp = 1.0e5
    wind1%mu = mui

    ! The spherical wind parameters of wind O4-5
    wind2%xc = x2 
    wind2%yc = y2 
    wind2%zc = z2
    wind2%radius = 2.0 * AU
    wind2%mdot = 4.5e-8 * MSUN/YR
    wind2%vinf = 500 * KPS
    wind2%temp = 1.0e4
    wind2%mu = mui

    ! Then we impose the wind source
    call imposeSphericalWind(wind1, uvars)
    call imposeSphericalWind(wind2, uvars)

    ! ============================================
    
  end subroutine userInitialCondition

  !=============================================================================

  subroutine userBoundary (uvars)
  ! ============================================
  ! [4] USER-DEFINED BOUNDARY CONDITIONS
  !
  !< @brief User-defined Boundary Conditions
  !< @details This subroutine is called once per timestep *after* standard
  !! boundary have been applied to all blocks. It allows the user to
  !! to impose an arbitrary boundary condition on the simulation.
  !!
  !! IMPORTANT: This subroutine receives the FLOW variables array to be 
  !! modified as argument 'uvars'. The subroutine must modify this array,
  !! *NOT* the global arrays U and UP.
  !!
  !! The structure of this array is described in the userInitialConditions()
  !! subroutine documentation above.
  ! ============================================

    implicit none
    real, intent(inout) :: uvars (nbMaxProc, neqtot, &
                           nxmin:nxmax, nymin:nymax, nzmin:nzmax)

! ============================================
    ! > YOUR BOUNDARY CONDITIONS CODE HERE <  

    ! operation to get the phase of the orbit 
    phase = mod(time*t_sc,Pe)/Pe +0.25
    ! routine to modify the configuration state of the source winds
    call computeBinary(phase, x1, y1, x2, y2, vx1, vy1, vx2, vy2)

    ! update position wind 1
    wind1%xc = x1
    wind1%yc = y1
    
    ! update position wind 2
    wind2%xc = x2
    wind2%yc = y2
    
    ! Refresh the wind source every iteration
    call imposeSphericalWind(wind1, uvars)
    call imposeSphericalWind(wind2, uvars)

    ! ============================================

  end subroutine userBoundary

end module userconds
