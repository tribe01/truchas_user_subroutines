double precision function qlaser (v, p) bind(c)
  use lib_array
  use Path
  implicit none

  ! input variables
  ! v( t, x, y, z)
  ! model parameters, eta = eta_b*eta_e)
  ! p=( electrical_resistivity, laser_wavelength, beam_radius, penetration, ztop)

  double precision v(*), p(*)

  logical :: isread
  character(len=80) :: filename
  integer :: idx
  double precision :: x,gammax,gammay,gammaz
  double precision :: x2, y2, z2, z
  double precision :: ratio, absorp, prefac, rd2, pwrv
  double precision :: tfil=0
  
  ratio = p(1)/p(2)
  absorp = 0.365*((ratio)**(0.5)) - 0.0667*ratio + 0.006*((ratio)**(1.5))
  rd2=p(3)*p(3)
  prefac=absorp/(((3.14159265359)**2*rd2*p(4)))

  ! check if path is read into memory
  isread=isPathSet()
  if(.not.isread)then
     write(*,*) 'Path is not set'
     filename="xyzdtp.dat"
     call initTime(filename)
     ! size of the read path
     ! iPathN=number of linear segments
     ! CAM(1:iPathN)=incremental cumulative time
    ! write(*,1004) 'iPathN= ', iPathN, ' pathLength= ', pathLength
     !write(*,1005) 'CAM(1)= ', CAM(1), 'CAM(iPathN)= ', CAM(iPathN)
  endif

  x=v(1)      ! current time

  ! to avoid recalculating coordinates for the same time
  if(lastTime /= v(1))then
     !write(*,*) 'New time'
     ! locate starting index of a segment for given distance along path length 
     idx = locate(CAM(1:iPathN), x)
     if(idx .le. 0)then
      !  write(*,1001) 'Time ', x, 'out of bounds. ',idx
 !       write(*,*) 'Time ', x, 'out of bounds.'
        qlaser=0D0
        return
     endif

!     write(*,*) 'idx = ', idx, CAM(idx), CAM(idx+1)

     idx=idx+1
     ! read beam cooridantes
     gammax=XAM(idx)
     gammay=YAM(idx)
     !  write(*,*) 'Time= ', x, ' X= ', gammax, ' Y= ', gammay

     lastPower=POW(idx)
     lastTime=v(1)
     lastX=gammax
     lastY=gammay
  endif

  gammax=lastX
  gammay=lastY
  pwrv=lastPower
  gammaz=p(5)
  qlaser=0D0

!  write(*,1002) 'T= ', x, ' i= ', idx, ' (', lastX, ',', lastY, ')', ' P= ',lastPower

  x2=( v(2) - gammax )**2
  y2=( v(3) - gammay )**2
  z2=( v(4) - gammaz )**2
  z=sqrt(z2)/p(4)

  if(z .ge. 2.0)then
     qlaser=0D0
  else
     ! Truchas Physics and Algorithms, LA-UR-08-0819
     ! Prod. Eng. Res. Devel. (2010) 4:15-23, Eq. 5
  qlaser=3*prefac*pwrv*exp(-3*(x2+y2)/rd2)
  endif

1001 format(A10,e12.4,A16,i3)
1002 format(A3,e12.4,A4,i3,A2,e12.4,A1,e12.4,A1,A4,e12.4)
1004 format(A8,i5,A14,e12.4)
1005 format(A8,e12.4,A14,e12.4)
  

  return
end function qlaser
