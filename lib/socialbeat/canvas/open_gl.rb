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
    self.width = w
    self.height = h
  end
  
  # Drawing!
  # TODO: Only expose drawing methods to the artist, not the methods above
  attr_accessor :width, :height

  def use_3d!
    glViewport(0, 0, self.width, self.height)
  
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity
    # Calculate aspect ratio of the window
    gluPerspective(45.0, self.width / self.height, 0.1, 400.0)

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity
  end

  def use_2d!
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glScalef(2.0 / width, -2.0 / height, 1.0);
    glTranslatef(-(width / 2.0), -(height / 2.0), 0.0);
    glViewport(0, 0, width, height); 
  end

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

  def point(*position)
    glPushMatrix
      glTranslate(*position)
      size = 2.0
      glScale(0.5, 0.5, 1.0)
      glBegin(GL_QUADS)
        Gl.glNormal(1.0, 1.0, 1.0);
        Gl.glVertex(-size, -size, 0.0);
        Gl.glVertex(size, -size, 0.0);
        Gl.glVertex(size, size, 0.0);
        Gl.glVertex(-size, size, 0.0);
      glEnd
    glPopMatrix
  end

  def look_at(eye, centre, up)
    gluLookAt(*(eye + centre + up))
  end

  def rotate(amount, axis)
    glRotate(amount, *axis)
  end
end

end; end;
