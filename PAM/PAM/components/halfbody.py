from __future__ import division
from PAM.components import component, Property, fuse_sections
import numpy, pylab
import mpl_toolkits.mplot3d.axes3d as p3


class halfbody(component):

    def __init__(self, nx, ny, nz, full=False):
        if full:
            self.faces = numpy.zeros((6,2),int)
        else:
            self.faces = numpy.zeros((5,2),int)
        self.faces[0,:] = [-2,3]
        self.faces[1,:] = [3,1]
        self.faces[2,:] = [-2,1]
        self.faces[3,:] = [-3,1]
        self.faces[4,:] = [-2,-3]
        if full:
            self.faces[5,:] = [2,1]

        Ps = []
        Ks = []

        P, K = self.createSurfaces(Ks, ny, nz, -2, 3, 0)
        Ps.extend(P)
        Ks.append(K)
         
        P, K = self.createSurfaces(Ks, nz, nx, 3, 1, 1)
        Ps.extend(P) 
        Ks.append(K)
           
        P, K = self.createSurfaces(Ks, ny, nx, -2, 1, 1)
        Ps.extend(P)  
        Ks.append(K)  
      
        P, K = self.createSurfaces(Ks, nz, nx, -3, 1, 0)
        Ps.extend(P)   
        Ks.append(K)

        P, K = self.createSurfaces(Ks, ny, nz, -2, -3, 1)
        Ps.extend(P) 
        Ks.append(K) 

        if full:
            P, K = self.createSurfaces(Ks, ny, nx, 2, 1, 0)
            Ps.extend(P) 
            Ks.append(K)             

        self.nx = nx
        self.ny = ny
        self.nz = nz
        self.Ps = Ps   
        self.Ks = Ks  
        self.full = full

        self.oml0 = [] 

    def setDOFs(self):
        oml0 = self.oml0
        for f in range(len(self.Ks)):
            for j in range(self.Ks[f].shape[1]):
                for i in range(self.Ks[f].shape[0]):
                    oml0.surf_c1[self.Ks[f][i,j],:,:] = True
        if not self.full:
            for f in [0]:
                for j in [0]:
                    for i in range(self.Ks[f].shape[0]):
                        oml0.surf_c1[self.Ks[f][i,j],:,0] = False
                        edge = oml0.surf_edge[self.Ks[f][i,j],0,0]
                        edge = abs(edge) - 1
                        oml0.edge_c1[edge,:] = True
            for f in [1]:
                for j in range(self.Ks[f].shape[1]):
                    for i in [0]:
                        oml0.surf_c1[self.Ks[f][i,j],0,:] = False
                        edge = oml0.surf_edge[self.Ks[f][i,j],1,0]
                        edge = abs(edge) - 1
                        oml0.edge_c1[edge,:] = True
            for f in [3]:
                for j in range(self.Ks[f].shape[1]):
                    for i in [-1]:
                        oml0.surf_c1[self.Ks[f][i,j],-1,:] = False
                        edge = oml0.surf_edge[self.Ks[f][i,j],1,1]
                        edge = abs(edge) - 1
                        oml0.edge_c1[edge,:] = True
            for f in [4]:
                for j in [-1]:
                    for i in range(self.Ks[f].shape[0]):
                        oml0.surf_c1[self.Ks[f][i,j],:,-1] = False
                        edge = oml0.surf_edge[self.Ks[f][i,j],0,1]
                        edge = abs(edge) - 1
                        oml0.edge_c1[edge,:] = True

    def isExteriorDOF(self, f, uType, vType):
        value = False
        if self.full:
            value = False
        elif f==0:
            if uType==2 and vType==0:
                value = True
        elif f==1:
            if uType==0 and vType==2:
                value = True
        elif f==3:
            if uType==-1 and vType==2:
                value = True
        elif f==4:
            if uType==2 and vType==-1:
                value = True
        return value

    def initializeParameters(self):
        Ns = self.Ns
        self.offset = numpy.zeros(3)
        self.props = {
            'posx':Property(Ns[1].shape[1]),
            'posy':Property(Ns[1].shape[1]),
            'ry':Property(Ns[1].shape[1]),
            'rz':Property(Ns[1].shape[1]),
            'noseL':0.1,
            'tailL':0.05
            }
        self.sections = []
        for i in range(Ns[1].shape[1]):
            self.sections.append(fuse_sections.circular)

    def setSections(self, section, shape):
        Ns = self.Ns
        for j in range(Ns[2].shape[1]):
            for i in range(Ns[2].shape[0]):
                val = Ns[2][i,j,3]
                if not val == -1:
                    break
            if val==section:
                self.sections[j] = shape

    def propagateQs(self):
        wR = 0.8
        wL = 0.9
        wD = 1.1
        Ns = self.Ns
        Qs = self.Qs
        for f in range(len(Ns)):
            if f==0 or f==4:
                if f==0:
                    sect = 1
                    i1 = 1
                    i2 = 2
                    L = wL*self.props['noseL']
                else:
                    sect = -2
                    i1 = -3
                    i2 = -2
                    L = -wL*self.props['tailL']
                posx = self.props['posx'].data[sect]
                posy = self.props['posy'].data[sect]
                rz = wR*self.props['rz'].data[sect]
                ry = wR*self.props['ry'].data[sect]
                dx = self.props['posx'].data[i2] - self.props['posx'].data[i1]
                dy = self.props['ry'].data[i2] - self.props['ry'].data[i1]
                dz = self.props['rz'].data[i2] - self.props['rz'].data[i1]    
                d = wD*abs(dy/dx)
                e = wD*abs(dz/dx)
                for j in range(Ns[f].shape[1]):
                    for i in range(Ns[f].shape[0]):
                        yy = 1 - 2*i/(Ns[f].shape[0]-1)
                        if self.full:
                            zz = -1 + 2*j/(Ns[f].shape[1]-1)
                        elif f==0:
                            zz = j/(Ns[f].shape[1]-1)
                        elif f==4:
                            zz = -1 + j/(Ns[f].shape[1]-1)
                        x,y,z = fuse_sections.cone(L,rz,ry,d,e,yy,zz)
                        Qs[f][i,j,:] = self.offset + [posx,posy,0] + [x,y,z] 
                        Qs[f][i,j,0] -= self.props['posx'].data[1]
                        if f==4:
                            Qs[f][i,j,0] += self.props['noseL']
                            Qs[f][i,j,0] += (1-wL)*self.props['tailL']
            else:
                pi = numpy.pi
                for j in range(Ns[f].shape[1]):
                    posx = self.props['posx'].data[j]
                    posy = self.props['posy'].data[j]
                    rz = self.props['rz'].data[j]
                    ry = self.props['ry'].data[j]
                    for i in range(Ns[f].shape[0]):
                        ii = i/(Ns[f].shape[0]-1)
                        if f==1 and self.full:
                            t = 3/4.0 - ii/2.0
                        elif f==1 and not self.full:
                            t = 1/2.0 - ii/4.0
                        elif f==2:
                            t = 1/4.0 - ii/2.0
                        elif f==3 and self.full:
                            t = 7/4.0 - ii/2.0
                        elif f==3 and not self.full:
                            t = 7/4.0 - ii/4.0
                        elif f==5:
                            t = 5/4.0 - ii/2.0
                        if t < 0:
                            t += 2
                        z,y = self.sections[j](rz,ry,t)
                        Qs[f][i,j,:] = self.offset + [posx,posy,0] + [0,y,z]
                        Qs[f][i,j,0] += self.props['noseL'] - self.props['posx'].data[1]
        


if __name__ == '__main__':  

    h = halfbody([2,3],[3,4],[3,3],full=True)
    P = h.Ps
    print h.Ks
    
    ax = p3.Axes3D(pylab.figure())
    for k in range(len(P)):
        ax.plot_wireframe(P[k][:,:,0],P[k][:,:,1],P[k][:,:,2])
    pylab.show()
