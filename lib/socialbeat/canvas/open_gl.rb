require 'rubygems'
require 'opengl'

module SocialBeat; module Canvas;

class OpenGl
  include Gl, Glut

  attr_accessor :on_idle
  attr_accessor :on_display

  def init
    Glut.glutInit
    Glut.glutInitDisplayMode(Glut::GLUT_SINGLE | Glut::GLUT_RGB | Glut::GLUT_DEPTH);
    Glut.glutInitWindowSize(800, 600);
    Glut.glutCreateWindow($0);

    glDepthFunc(Gl::GL_LESS);
    glShadeModel(GL_SMOOTH) # Select Smooth Shading
    glEnable(Gl::GL_DEPTH_TEST);

    Glut.glutReshapeFunc(method(:reshape).to_proc);
    Glut.glutDisplayFunc(method(:display).to_proc);
    Glut.glutIdleFunc(method(:idle).to_proc);
    Glut.glutMainLoop();
  end

  def display
    Gl.glClear(Gl::GL_COLOR_BUFFER_BIT | Gl::GL_DEPTH_BUFFER_BIT);

    self.on_display.call

    Gl.glFlush();
    Glut.glutSwapBuffers()
  end

  def idle
    self.on_idle.call
  end

  def refresh
    glutPostRedisplay()
  end
  
  def reshape(w, h)
    Gl.glViewport(0, 0, w, h);
    Gl.glMatrixMode(Gl::GL_PROJECTION);
    Gl.glLoadIdentity();
    Gl.glOrtho(-w/2.0, w/2.0, -h/2.0, h/2.0, -10.0, 10.0)
    Gl.glMatrixMode(Gl::GL_MODELVIEW);

    self.width = w
    self.height = h
  end

  attr_accessor :width, :height


  # Drawing!
  def fill(r, g, b)
    glColor(r, g, b)
  end

  def circle(x, y, r)
    # Uhm yeah so this isn't really a circle yet
    Gl.glPushMatrix();
      glTranslatef(x, y, 0);
      glScale(r, r, 0)
      Gl.glBegin(Gl::GL_QUADS);
      Gl.glNormal(0.0, 0.0, 1.0);
      Gl.glVertex(-1.0, -1.0, 0.0);
      Gl.glVertex(0.0, -1.0, 0.0);
      Gl.glVertex(0.0, 0.0, 0.0);
      Gl.glVertex(-1.0, 0.0, 0.0);

      Gl.glNormal(0.0, 0.0, 1.0);
      Gl.glVertex(0.0, -1.0, 0.0);
      Gl.glVertex(1.0, -1.0, 0.0);
      Gl.glVertex(1.0, 0.0, 0.0);
      Gl.glVertex(0.0, 0.0, 0.0);

      Gl.glNormal(0.0, 0.0, 1.0);
      Gl.glVertex(0.0, 0.0, 0.0);
      Gl.glVertex(1.0, 0.0, 0.0);
      Gl.glVertex(1.0, 1.0, 0.0);
      Gl.glVertex(0.0, 1.0, 0.0);

      Gl.glNormal(0.0, 0.0, 1.0);
      Gl.glVertex(0.0, 0.0, 0.0);
      Gl.glVertex(0.0, 1.0, 0.0);
      Gl.glVertex(-1.0, 1.0, 0.0);
      Gl.glVertex(-1.0, 0.0, 0.0);
      Gl.glEnd();
    Gl.glPopMatrix();
  end
end

end; end;
