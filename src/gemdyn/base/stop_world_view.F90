!---------------------------------- LICENCE BEGIN -------------------------------
! GEM - Library of kernel routines for the GEM numerical atmospheric model
! Copyright (C) 1990-2010 - Division de Recherche en Prevision Numerique
!                       Environnement Canada
! This library is free software; you can redistribute it and/or modify it
! under the terms of the GNU Lesser General Public License as published by
! the Free Software Foundation, version 2.1 of the License. This library is
! distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
! without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
! PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
! You should have received a copy of the GNU Lesser General Public License
! along with this library; if not, write to the Free Software Foundation, Inc.,
! 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
!---------------------------------- LICENCE END ---------------------------------

!**s/r stop_world_view - Update status file and stop MPI

      subroutine stop_world_view
      use phy_itf, only: phy_terminate
      use step_options
      use gem_options
      use ctrl
      use lun
      use path
      use clib_itf_mod
      use adz_mem
      use ptopo
      use version
      use gem_timing
      implicit none
#include <arch_specific.hf>
      integer, external :: exfin

      character(len=256) :: postjob_S
      logical continue_L
      integer i,err
!
!-------------------------------------------------------------------
!
      if (Ctrl_phyms_L) err = phy_terminate()

      continue_L= (Step_kount < Step_total)

      if (Lun_out > 0) then
         write (postjob_S,34) Lctl_step
         postjob_S='_endstep='//trim(postjob_S)
         call write_status_file3 (postjob_S)
         if (continue_L) then
            call write_status_file3 ('_status=RS')
         else
            call write_status_file3 ('_status=ED')
         end if
         call close_status_file3 ()
      end if

      if (Lun_out > 0) call out_stat2 ()

      if (.not. continue_L) then
         err = clib_remove('gem_restart')
         err = clib_remove('gmm_restart')
      end if

      err= clib_remove(trim(Path_nml_S))
      err= clib_remove(trim(Path_outcfg_S))
      err= clib_remove(trim(Path_phyincfg_S))

      call gemtime ( Lun_out, 'END OF RUN', .true. )
      call memusage ( Lun_out )

      call gemtime_stop ( 1 )
      call gemtime_terminate( Ptopo_myproc, 'GEMDM' )

      if (Lun_out > 0) then
         if (ADZ_OD_L) then
            do i=1, size(nexports)
               print*, 'EXPORTS: ',i,nexports(i)/Ptopo_numproc
            enddo
         endif
         err = exfin (trim(Version_title_S),trim(Version_number_S), 'OK')
      end if

      call rpn_comm_FINALIZE(err)

 34   format (i10.10)
!
!-------------------------------------------------------------------
!
      return
      end
