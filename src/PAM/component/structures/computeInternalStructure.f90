subroutine assembleAmtx(nA, n0, nP, nJ1, nJ2, nvert, nquad, &
     Jn1, Jn2, Ju1, Ju2, quad_indices, verts, poly_vert, P, M, Aa, Ai, Aj)

  implicit none

  !Fortran-python interface directives
  !f2py intent(in) nA, n0, nP, nJ1, nJ2, nvert, nquad, Jn1, Jn2, Ju1, Ju2, quad_indices, verts, poly_vert, P, M
  !f2py intent(out) Aa, Ai, Aj
  !f2py depend(nJ1) Jn1
  !f2py depend(nJ2) Jn2
  !f2py depend(nJ1) Ju1
  !f2py depend(nJ2) Ju2
  !f2py depend(nquad) quad_indices
  !f2py depend(nvert) verts
  !f2py depend(nquad) poly_vert
  !f2py depend(nP) P, M
  !f2py depend(nA) Aa, Ai, Aj

  !Input
  integer, intent(in) ::  nA, n0, nP, nJ1, nJ2, nvert, nquad
  integer, intent(in) ::  Jn1(nJ1,4), Jn2(nJ2,4)
  double precision, intent(in) ::  Ju1(nJ1,4), Ju2(nJ2,4)
  integer, intent(in) ::  quad_indices(nquad,2)
  double precision, intent(in) ::  verts(nvert,2)
  integer, intent(in) ::  poly_vert(nquad,5)
  double precision, intent(in) ::  P(nP,3)
  integer, intent(in) ::  M(nP)

  !Output
  double precision, intent(out) ::  Aa(nA)
  integer, intent(out) ::  Ai(nA), Aj(nA)

  !Working
  integer iA, s, r, iP
  integer quad, jctn
  double precision uu, vv, Q(4,2)
  integer nu1, nu2, nv1, nv2
  double precision u1, u2, v1, v2
  double precision Pu, Pv, Pw

  Aa(:) = 0.0
  Ai(:) = 1
  Aj(:) = 1

  iA = 0
  do iP=1,nP
     do s=1,2
        do r=1,2
           if ((M(iP) .eq. 2) .and. (s .eq. 2)) then
              Pu = P(iP,1)
              Pv = 2.0 - r
              Pw = P(iP,3)
           else
              Pu = P(iP,1)
              Pv = P(iP,2)
              Pw = P(iP,3)
           end if
           call findQuaduv(nvert, nquad, Pu, Pv, verts, poly_vert, quad)
           if (quad_indices(quad,s) .eq. 0) then
              if (s .eq. 1) then
                 call findJunctionuv(quad, nvert, nquad, nJ1, &
                      verts, poly_vert, Ju1, jctn, Q)
                 nu1 = Jn1(jctn,1)
                 nu2 = Jn1(jctn,2)
                 nv1 = Jn1(jctn,3)
                 nv2 = Jn1(jctn,4)
                 u1 = Ju1(jctn,1)
                 u2 = Ju1(jctn,2)
                 v1 = Ju1(jctn,3)
                 v2 = Ju1(jctn,4)
              else
                 call findJunctionuv(quad, nvert, nquad, nJ2, &
                      verts, poly_vert, Ju2, jctn, Q)
                 nu1 = Jn2(jctn,1)
                 nu2 = Jn2(jctn,2)
                 nv1 = Jn2(jctn,3)
                 nv2 = Jn2(jctn,4)
                 u1 = Ju2(jctn,1)
                 u2 = Ju2(jctn,2)
                 v1 = Ju2(jctn,3)
                 v2 = Ju2(jctn,4)
              end if
              call appendJunctionA(s, M(iP), jctn, nA, n0, nquad, nJ1, nJ2, nvert, &
                   nu1, nu2, nv1, nv2, u1, u2, v1, v2, verts, quad_indices, &
                   Jn1, Jn2, Pu, Pv, Pw, iP, iA, Aa, Ai, Aj)
           else
              Q(1,:) = verts(poly_vert(quad,1),:)
              Q(2,:) = verts(poly_vert(quad,2),:)
              Q(3,:) = verts(poly_vert(quad,3),:)
              Q(4,:) = verts(poly_vert(quad,4),:)
              call invBilinearMap(Pu, Pv, Q, uu, vv)
              call appendQuadA(s, M(iP), quad, nA, n0, nquad, nJ1, &
                   quad_indices, Jn1, uu, vv, Pw, iP, iA, Aa, Ai, Aj)
           end if
        end do
     end do
  end do

  do iA=1,nA
     Ai(iA) = Ai(iA) - 1
     Aj(iA) = Aj(iA) - 1
  end do

end subroutine assembleAmtx



subroutine countAnnz(nP, nvert, nquad, verts, poly_vert, quad_indices, P, M, nA)

  implicit none

  !Fortran-python interface directives
  !f2py intent(in) nP, nvert, nquad, verts, poly_vert, quad_indices, P, M
  !f2py intent(out) nA
  !f2py depend(nvert) verts
  !f2py depend(nquad) poly_vert, quad_indices
  !f2py depend(nP) P, M

  !Input
  integer, intent(in) ::  nP, nvert, nquad
  double precision, intent(in) ::  verts(nvert,2)
  integer, intent(in) ::  poly_vert(nquad,5), quad_indices(nquad,2)
  double precision, intent(in) ::  P(nP,3)
  integer, intent(in) ::  M(nP)

  !Output
  integer, intent(out) ::  nA

  !Working
  integer iP, quad, s, r
  double precision Pu, Pv

  nA = 0
  do iP=1,nP
     do s=1,2
        do r=1,2
           if ((M(iP) .eq. 2) .and. (s .eq. 2)) then
              Pu = P(iP,1)
              Pv = 2.0 - r
           else
              Pu = P(iP,1)
              Pv = P(iP,2)
           end if
           call findQuaduv(nvert, nquad, Pu, Pv, verts, poly_vert, quad)
           if (quad_indices(quad,s) .eq. 0) then
              nA = nA + 12
           else
              nA = nA + 4
           end if
        end do
     end do
  end do

end subroutine countAnnz



subroutine computeInternalNodes(nP, nS, n0, nM, members, P, M, S)

  implicit none

  !Fortran-python interface directives
  !f2py intent(in) nP, nS, n0, nM, members
  !f2py intent(out) P, M, S
  !f2py depend(nM) members
  !f2py depend(nP) P, M
  !f2py depend(nS) S

  !Input
  integer, intent(in) ::  nP, nS, n0, nM
  double precision, intent(in) ::  members(nM,34)

  !Output
  double precision, intent(out) ::  P(nP,3)
  integer, intent(out) ::  M(nP), S(nS,2)

  !Working
  integer iM, mem, div, iP, iS, i
  integer domain, shape, nmem, ndiv, n1, n2, n
  double precision mm, dd
  double precision A(3), B(3), C(3), D(3)
  double precision A0(3), B0(3), C0(3), D0(3)
  double precision A1(3), B1(3), C1(3), D1(3)
  double precision A2(3), B2(3), C2(3), D2(3)
  double precision, allocatable, dimension(:) ::  u0, v0, u, v, w
  
  P(:,:) = 0.0

  iP = 0
  iS = 0
  do iM=1,nM
     domain = int(members(iM,1))
     shape = int(members(iM,2))
     nmem = int(members(iM,3))
     ndiv = int(members(iM,4))
     n1 = int(members(iM,33))
     n2 = int(members(iM,34))
     A1 = members(iM,5:7)
     B1 = members(iM,8:10)
     C1 = members(iM,11:13)
     D1 = members(iM,14:16)
     A2 = members(iM,17:19)
     B2 = members(iM,20:22)
     C2 = members(iM,23:25)
     D2 = members(iM,26:28)
     if (nmem .eq. 1) then
        mm = 0
     else
        mm = 1.0/(nmem-1)
     end if
     dd = 1.0/ndiv
     do mem=1,nmem
        call weightedAvg((mem-1)*mm, A1, A2, A0)
        call weightedAvg((mem-1)*mm, B1, B2, B0)
        call weightedAvg((mem-1)*mm, C1, C2, C0)
        call weightedAvg((mem-1)*mm, D1, D2, D0)
        do div=1,ndiv
           call weightedAvg((div-1)*dd, A0, D0, A)
           call weightedAvg((div-1)*dd, B0, C0, B)
           call weightedAvg(div*dd, B0, C0, C)
           call weightedAvg(div*dd, A0, D0, D)
           if (shape .eq. 1) then
              n = n0*n1
              iS = iS + 1
              S(iS,:) = (/ n0 , n1 /)
           else if (shape .eq. 2) then
              n = 2*n1*n2 + 2*n0*n2
              iS = iS + 1
              S(iS,:) = (/ n1 , n2 /)
              iS = iS + 1
              S(iS,:) = (/ n0 , n2 /)
              iS = iS + 1
              S(iS,:) = (/ n1 , n2 /)
              iS = iS + 1
              S(iS,:) = (/ n0 , n2 /)
           else
              n = 0
           end if
           if (n .ne. 0) then
              allocate(u0(n))
              allocate(v0(n))
              allocate(u(n))
              allocate(v(n))
              allocate(w(n))
              if (shape .eq. 1) then   
                 call getShapeRect(n, n0, n1, u0, v0)
              else if (shape .eq. 2) then
                 call getShapeHole(n, n0, n1, n2, u0, v0)
              else
                 print *, 'Shape not found'
              end if
              call projectuvw(n, A, B, C, D, u0, v0, u, v, w)
              do i=1,n
                 iP = iP + 1
                 P(iP,1) = u(i)
                 P(iP,2) = v(i)
                 P(iP,3) = w(i)
                 M(iP) = domain
              end do
              deallocate(u0)
              deallocate(v0)
              deallocate(u)
              deallocate(v)
              deallocate(w)
           end if
        end do
     end do
  end do

end subroutine computeInternalNodes



subroutine countInternalNodes(n0, nM, members, nP, nS)

  implicit none

  !Fortran-python interface directives
  !f2py intent(in) n0, nM, members
  !f2py intent(out) nP, nS
  !f2py depend(nM) members

  !Input
  integer, intent(in) ::  n0, nM
  double precision, intent(in) ::  members(nM,34)

  !Output
  integer, intent(out) ::  nP, nS

  !Working
  integer iM, mem, div
  integer shape, nmem, ndiv, n1, n2
  
  nP = 0
  nS = 0
  do iM=1,nM
     shape = int(members(iM,2))
     nmem = int(members(iM,3))
     ndiv = int(members(iM,4))
     n1 = int(members(iM,33))
     n2 = int(members(iM,34))
     do mem=1,nmem
        do div=1,ndiv
           if (shape .eq. 1) then
              nP = nP + n0*n1
              nS = nS + 1
           else if (shape .eq. 2) then
              nP = nP + 2*n0*n2 + 2*n1*n2
              nS = nS + 4
           end if
        end do
     end do
  end do

end subroutine countInternalNodes



subroutine writeToA(nA, a, i, j, iA, Aa, Ai, Aj)

  implicit none

  !Input
  integer, intent(in) ::  nA
  double precision, intent(in) ::  a
  integer, intent(in) ::  i, j
  
  !Output
  integer, intent(inout) ::  iA
  double precision, intent(inout) ::  Aa(nA)
  integer, intent(inout) ::  Ai(nA), Aj(nA)

  iA = iA + 1
  Aa(iA) = a
  Ai(iA) = i
  Aj(iA) = j

end subroutine writeToA



subroutine appendJunctionA(ss, domain, jctn, nA, n0, nquad, nJ1, nJ2, &
     nvert, nu1, nu2, nv1, nv2, u1, u2, v1, v2, verts, quad_indices, &
     Jn1, Jn2, uu, vv, ww, iP, iA, Aa, Ai, Aj)

  implicit none

  !Input
  integer, intent(in) ::  ss, domain, jctn, nA, n0, nquad, nJ1, nJ2, nvert
  integer, intent(in) ::  nu1, nu2, nv1, nv2
  double precision, intent(in) ::  u1, u2, v1, v2
  double precision, intent(in) ::  verts(nvert,2)
  integer, intent(in) ::  quad_indices(nquad,2)
  integer, intent(in) ::  Jn1(nJ1,4), Jn2(nJ2,4)
  double precision, intent(in) ::  uu, vv, ww
  integer, intent(in) ::  iP

  !Output
  integer, intent(inout) ::  iA
  double precision, intent(inout) ::  Aa(nA)
  integer, intent(inout) ::  Ai(nA), Aj(nA)

  !Working
  double precision u, v, w, t
  integer index, i1, i2, j1, j2, s
  double precision Cu1(nu1+1,2), Cu2(nu2+1,2), Cv1(nv1+1,2), Cv2(nv2+1,2)

  call getJunctionVerts(nvert, nu1, nu2, nv1, nv2, &
       u1, u2, v1, v2, verts, Cu1, Cu2, Cv1, Cv2)

  s = ss
  if (ss .eq. 1) then
     w = ww
  else
     w = 1-ww
  end if
  w = 0.5*w
  if ((domain .eq. 2) .and. (s .eq. 2)) then
     s = 1
  end if
  call nMap(uu,u1,u2,u)
  call nMap(vv,v1,v2,v)

  call getIndexJunction(s, jctn, 1, n0*nu1, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, -w*(1-u)*v, iP, index, iA, Aa, Ai, Aj)
  
  call getIndexJunction(s, jctn, 2, n0*nu2, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, -w*u*v, iP, index, iA, Aa, Ai, Aj)
  
  call getIndexJunction(s, jctn, 1, 1, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, -w*(1-u)*(1-v), iP, index, iA, Aa, Ai, Aj)
  
  call getIndexJunction(s, jctn, 2, 1, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, -w*u*(1-v), iP, index, iA, Aa, Ai, Aj)

  call classifyU2(n0, nu1+1, vv, Cu1(1,1), Cu1(:,2), i1, i2, t)
  call getIndexJunction(s, jctn, 1, i1, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, w*(1-t)*(1-u), iP, index, iA, Aa, Ai, Aj)
  call getIndexJunction(s, jctn, 1, i2, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, w*t*(1-u), iP, index, iA, Aa, Ai, Aj)
  
  call classifyU2(n0, nu2+1, vv, Cu2(1,1), Cu2(:,2), i1, i2, t)
  call getIndexJunction(s, jctn, 2, i1, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, w*(1-t)*u, iP, index, iA, Aa, Ai, Aj)
  call getIndexJunction(s, jctn, 2, i2, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, w*t*u, iP, index, iA, Aa, Ai, Aj)
  
  call classifyU2(n0, nv1+1, uu, Cv1(1,2), Cv1(:,1), j1, j2, t)
  call getIndexJunction(s, jctn, 3, j1, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, w*(1-t)*(1-v), iP, index, iA, Aa, Ai, Aj)
  
  call classifyU2(n0, nv1+1, uu, Cv1(1,2), Cv1(:,1), j1, j2, t)
  call getIndexJunction(s, jctn, 3, j2, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, w*t*(1-v), iP, index, iA, Aa, Ai, Aj)
  
  call classifyU2(n0, nv2+1, uu, Cv2(1,2), Cv2(:,1), j1, j2, t)
  call getIndexJunction(s, jctn, 4, j1, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, w*(1-t)*v, iP, index, iA, Aa, Ai, Aj)
  
  call classifyU2(n0, nv2+1, uu, Cv2(1,2), Cv2(:,1), j1, j2, t)
  call getIndexJunction(s, jctn, 4, j2, &
       n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)
  call writeToA(nA, w*t*v, iP, index, iA, Aa, Ai, Aj)
  
end subroutine appendJunctionA



subroutine classifyU2(n0, np1, u, cv, Cu, j1, j2, t)

  implicit none

  !Input
  integer, intent(in) ::  n0, np1
  double precision, intent(in) ::  u, cv
  double precision, intent(in) ::  Cu(np1)

  !Output
  integer, intent(out) ::  j1, j2
  double precision, intent(out) ::  t

  !Working
  integer edge
  integer i, i1, i2
  double precision t0, t1, t2

  j1 = 1
  j2 = 1
  t = 0.0  
  do i=1,np1-1
     if ((Cu(i) .le. u) .and. (u .le. Cu(i+1))) then
        edge = i
        call nMap(u,Cu(i),Cu(i+1),t0)
        call classifyU(n0, t0, i1, i2, t1, t2)
        call nMap(t0,t1,t2,t)
        j1 = n0*(edge-1) + i1
        j2 = n0*(edge-1) + i2
        exit
     end if
  end do
  if ((cv .le. 1e-14) .or. (cv .ge. 1 - 1e-14)) then
     j1 = 1
     j2 = n0*(np1-1)
     t1 = 0.0
     t2 = 1.0
     call nMap(u,Cu(1),Cu(np1),t0)
     call nMap(t0,t1,t2,t)
  end if

end subroutine classifyU2



subroutine appendQuadA(ss, domain, quad, nA, n0, nquad, nJ1, &
     quad_indices, Jn1, uu, vv, ww, iP, iA, Aa, Ai, Aj)

  implicit none

  !Input
  integer, intent(in) ::  ss, domain, quad, nA, n0, nquad, nJ1
  integer, intent(in) ::  quad_indices(nquad,2), Jn1(nJ1,4)
  double precision, intent(in) ::  uu, vv, ww
  integer, intent(in) ::  iP

  !Output
  integer, intent(inout) ::  iA
  double precision, intent(inout) ::  Aa(nA)
  integer, intent(inout) ::  Ai(nA), Aj(nA)

  !Working
  double precision u1, u2, v1, v2, w
  integer i1, i2, j1, j2, s
  integer index

  s = ss
  if (ss .eq. 1) then
     w = ww
  else
     w = 1-ww
  end if
  w = 0.5*w
  if ((domain .eq. 2) .and. (s .eq. 2)) then
     s = 1
  end if
  call classifyU(n0, uu, i1, i2, u1, u2)
  call classifyU(n0, vv, j1, j2, v1, v2)

  call getIndexQuad(s, quad, i1, j2, &
       n0, nquad, nJ1, quad_indices, Jn1, index)
  call writeToA(nA, w*(u2 - uu)*(vv - v1)*(n0-1)**2, &
       iP, index, iA, Aa, Ai, Aj)
  
  call getIndexQuad(s, quad, i2, j2, &
       n0, nquad, nJ1, quad_indices, Jn1, index)
  call writeToA(nA, w*(uu - u1)*(vv - v1)*(n0-1)**2, &
       iP, index, iA, Aa, Ai, Aj)
  
  call getIndexQuad(s, quad, i1, j1, &
       n0, nquad, nJ1, quad_indices, Jn1, index)
  call writeToA(nA, w*(u2 - uu)*(v2 - vv)*(n0-1)**2, &
       iP, index, iA, Aa, Ai, Aj)
  
  call getIndexQuad(s, quad, i2, j1, &
       n0, nquad, nJ1, quad_indices, Jn1, index)
  call writeToA(nA, w*(uu - u1)*(v2 - vv)*(n0-1)**2, &
       iP, index, iA, Aa, Ai, Aj)

end subroutine appendQuadA



subroutine classifyU(n, u, i1, i2, u1, u2)

  implicit none

  !Input
  integer, intent(in) ::  n
  double precision, intent(in) ::  u
 
  !Output
  integer, intent(out) :: i1, i2
  double precision, intent(out) ::  u1, u2

  !Working
  double precision den
  integer ii

  den = 1.0/(n-1)
  if (u .ge. (1 - 1e-14)) then
     ii = n - 1
  else
     ii = floor(u*(n-1)) + 1
  end if  
  i1 = ii
  i2 = ii + 1
  u1 = (ii-1)*den
  u2 = ii*den

end subroutine classifyU



subroutine getIndexQuad(s, quad, i, j, &
     n0, nquad, nJ1, quad_indices, Jn1, index)

  implicit none

  !Input
  integer, intent(in) ::  s, quad, i, j
  integer, intent(in) ::  n0, nquad, nJ1
  integer, intent(in) ::  quad_indices(nquad,2)
  integer, intent(in) ::  Jn1(nJ1,4)

  !Output
  integer, intent(out) ::  index

  if (s .eq. 1) then
     index = n0**2*(quad_indices(quad,1)-1) + i + (j-1)*n0
  else     
     index = n0**2*(maxval(quad_indices(:,1))) &
          + n0**2*(quad_indices(quad,2)-1) + i + (j-1)*n0
     if (Jn1(1,1) .ne. -1) then
        index = index + n0*sum(Jn1(:,:))
     end if
  end if

end subroutine getIndexQuad



subroutine getIndexJunction(s, jctn, edge, i, &
     n0, nquad, nJ1, nJ2, quad_indices, Jn1, Jn2, index)

  implicit none

  !Input
  integer, intent(in) ::  s, jctn, edge, i
  integer, intent(in) ::  n0, nquad, nJ1, nJ2
  integer, intent(in) ::  quad_indices(nquad,2)
  integer, intent(in) ::  Jn1(nJ1,4), Jn2(nJ2,4)

  !Output
  integer, intent(out) ::  index

  if (s .eq. 1) then
     index = n0**2*maxval(quad_indices(:,1)) + n0*sum(Jn1(1:jctn-1,:)) &
          + n0*sum(Jn1(jctn,1:edge-1)) + i
  else    
     index = n0**2*(maxval(quad_indices(:,1)) + maxval(quad_indices(:,2))) &
          + n0*sum(Jn2(1:jctn-1,:)) + n0*sum(Jn2(jctn,1:edge-1)) + i
     if (Jn1(1,1) .ne. -1) then
        index = index + n0*sum(Jn1(:,:))
     end if
  end if

end subroutine getIndexJunction



subroutine findJunctionuv(quad, nvert, nquad, nJ, &
     verts, poly_vert, Ju, jctn, Q)

  implicit none

  !Input
  integer, intent(in) ::  quad, nvert, nquad, nJ
  double precision, intent(in) ::  verts(nvert,2)
  integer, intent(in) ::  poly_vert(nquad,5)
  double precision, intent(in) ::  Ju(nJ,4)

  !Output
  integer, intent(out) ::  jctn
  double precision, intent(out) ::  Q(4,2)

  !Working
  integer i
  double precision P(2)

  P(:) = 0.0
  do i=1,4
     P(:) = P(:) + 0.25*verts(poly_vert(quad,i),:)
  end do

  jctn = 0
  do i=1,nJ
     if ((Ju(i,1) .le. P(1)) .and. (P(1) .le. Ju(i,2)) .and. &
          (Ju(i,3) .le. P(2)) .and. (P(2) .le. Ju(i,4))) then
        jctn = i
        exit
     end if
  end do
  if (jctn .eq. 0) then
     print *, 'Error: junction not found'
  end if

  Q(1,:) = (/ Ju(jctn,1), Ju(jctn,3) /)
  Q(2,:) = (/ Ju(jctn,1), Ju(jctn,4) /)
  Q(3,:) = (/ Ju(jctn,2), Ju(jctn,4) /)
  Q(4,:) = (/ Ju(jctn,2), Ju(jctn,3) /)

end subroutine findJunctionuv



subroutine invBilinearMap(x, y, Q, u, v)

  implicit none

  !Input
  double precision, intent(in) ::  x, y, Q(4,2)

  !Output
  double precision, intent(out) ::  u, v

  !Working
  double precision P0(2), P1(2), P2(2), P3(2), P4(2)
  double precision A, B, C, B1, B2
  double precision u1, u2
  double precision P14(2), P23(2)

  P0(:) = (/ x , y /)
  P1(:) = Q(1,:)
  P2(:) = Q(2,:)
  P3(:) = Q(3,:)
  P4(:) = Q(4,:)

  call crossproduct(P1 - P4, P3 - P2, A)
  call crossproduct(P0 - P1, P3 - P2, B1)
  call crossproduct(P0 - P2, P1 - P4, B2)
  call crossproduct(P0 - P1, P2 - P1, C)
  B = B1 + B2

  if (abs(A) .lt. 1e-14) then
     u = -C/B
  else
     u1 = (-B - (B**2 - 4*A*C)**0.5)/2.0/A
     u2 = (-B + (B**2 - 4*A*C)**0.5)/2.0/A
     if ((0 .le. u1) .and. (u1 .le. 1)) then
        u = u1
     else
        u = u2   
     end if
  end if

  P14 = P1 + (P4-P1)*u
  P23 = P2 + (P3-P2)*u
  if (abs(P23(1) - P14(1)) .gt. abs(P23(2) - P14(2))) then
     v = (P0(1) - P14(1))/(P23(1) - P14(1))
  else
     v = (P0(2) - P14(2))/(P23(2) - P14(2))
  end if

end subroutine invBilinearMap



subroutine findQuaduv(nvert, nquad, u, v, verts, poly_vert, quad)

  implicit none

  !Input
  integer, intent(in) ::  nvert, nquad
  double precision, intent(in) ::  u, v
  double precision, intent(in) ::  verts(nvert,2)
  integer, intent(in) ::  poly_vert(nquad,5)

  !Output
  integer, intent(out) ::  quad

  !Working
  integer q, k
  double precision C(5,2), E(2), D(2), P0(2), cross
  logical contained

  P0(1) = u
  P0(2) = v

  quad = 0
  do q=1,nquad
     do k=1,4
        C(k,:) = verts(poly_vert(q,k),:)
     end do
     C(5,:) = C(1,:)
     
     contained = .True.
     do k=1,4
        E = C(k+1,:) - C(k,:)
        D = P0 - C(k,:)
        call crossproduct(D,E,cross)
        if (cross .lt. 0) then
           contained = .False.
        end if
     end do

     if (contained) then
        quad = q
        exit
     end if
  end do
  if (quad .eq. 0) then
     print *, 'Error: quad not found'
  end if

end subroutine findQuaduv



subroutine crossproduct(D,E,cross)

  implicit none

  !Input
  double precision, intent(in) ::  D(2), E(2)

  !Output
  double precision, intent(out) ::  cross

  cross = D(1)*E(2) - D(2)*E(1)

end subroutine crossproduct



subroutine projectuvw(n, A, B, C, D, u0, v0, u, v, w)

  implicit none

  !Input
  integer, intent(in) ::  n
  double precision, intent(in) ::  A(3), B(3), C(n), D(n)
  double precision, intent(in) ::  u0(n), v0(n)

  !Output
  double precision, intent(out) :: u(n), v(n), w(n)

  !Working
  double precision P(3)
  integer k

  u(:) = 0.0
  v(:) = 0.0
  w(:) = 0.0
  do k=1,n
     P(:) = 0.0
     P = P + A*(1 - u0(k))*(1 - v0(k))
     P = P + B*(1 - u0(k))*(v0(k) - 0)
     P = P + C*(u0(k) - 0)*(v0(k) - 0)
     P = P + D*(u0(k) - 0)*(1 - v0(k))
     u(k) = P(1)
     v(k) = P(2)
     w(k) = P(3)
     if (u(k) .lt. 0) then
        u(k) = 0
     else if (u(k) .gt. 1) then
        u(k) = 1
     end if
     if (v(k) .lt. 0) then
        v(k) = 0
     else if (v(k) .gt. 1) then
        v(k) = 1
     end if
     if (w(k) .lt. 0) then
        w(k) = 0
     else if (w(k) .gt. 1) then
        w(k) = 1
     end if
  end do

end subroutine projectuvw



subroutine weightedAvg(r, v1, v2, v)

  implicit none

  !Input
  double precision, intent(in) ::  r, v1(3), v2(3)

  !Output
  double precision, intent(out) ::  v(3)

  v = v1*(1-r) + v2*r

end subroutine weightedAvg
