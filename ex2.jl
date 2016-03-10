import GLFW
using ModernGL, GeometryTypes

function windowhints()
  hints = [
    (GLFW.SAMPLES,      4),
    (GLFW.DEPTH_BITS,   0),
    (GLFW.ALPHA_BITS,   8),
    (GLFW.RED_BITS,     8),
    (GLFW.GREEN_BITS,   8),
    (GLFW.BLUE_BITS,    8),
    (GLFW.STENCIL_BITS, 0),
    (GLFW.AUX_BUFFERS,  0),
    (GLFW.CONTEXT_VERSION_MAJOR, 3),
    (GLFW.CONTEXT_VERSION_MINOR, 2),
    (GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE),
    (GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
  ]
  for (key, value) in hints
    GLFW.WindowHint(key, value)
  end
end

windowhints()

window = GLFW.CreateWindow(800, 600, "Rock'n'roll")
GLFW.MakeContextCurrent(window)
# This is a touch added from
#   http://www.opengl-tutorial.org/beginners-tutorials/tutorial-1-opening-a-window/:
# Retain keypress events until the next call to GLFW.GetKey, even if
# the key has been released in the meantime
GLFW.SetInputMode(window, GLFW.STICKY_KEYS, GL_TRUE)

vao = Ref(GLuint(0))
glGenVertexArrays(1, vao)
glBindVertexArray(vao[])

vertices = Point{5,Float32}[
   (0.0,  0.5, 1.0, 0.0, 0.0),
   (0.5, -0.5, 0.0, 1.0, 0.0),
  (-0.5, -0.5, 0.0, 0.0, 1.0)]

vbo = Ref(GLuint(0))
glGenBuffers(1, vbo)
glBindBuffer(GL_ARRAY_BUFFER, vbo[])
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

vertexsrc = """
  #version 150

  in vec2 position;
  in vec3 color;

  out vec3 Color;

  void main()
  {
    Color = color;
    gl_Position = vec4(position, 0.0, 1.0);
  }
  """

fragmentsrc = """
  #version 150

  uniform vec3 triangleColor;

  in vec3 Color;

  out vec4 outColor;

  void main()
  {
    outColor = vec4(Color, 1.0);
  }
  """

function ModernGL.glShaderSource(shaderID::GLuint, shadercode::AbstractString)
  src = Vector{UInt8}(ascii(shadercode))
  shader_code_ptrs = Ptr{UInt8}[pointer(src)]
  len              = Ref{GLint}(length(src))
  glShaderSource(shaderID, 1, shader_code_ptrs, len)
end

function check_shader_compile()
  status = Ref(GLint(0))
  glGetShaderiv(vertexshader, GL_COMPILE_STATUS, status)
  if status[] != GL_TRUE
    buffer = Array(UInt8, 512)
    glGetShaderInfoLog(vertex_shader, 512, C_NULL, buffer)
    error(bytestring(buffer))
  end
end


vertexshader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertexshader, vertexsrc)
glCompileShader(vertexshader)

check_shader_compile()

fragmentshader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragmentshader, fragmentsrc)
glCompileShader(fragmentshader)

check_shader_compile()

shaderprogram = glCreateProgram()
glAttachShader(shaderprogram, vertexshader)
glAttachShader(shaderprogram, fragmentshader)

glBindFragDataLocation(shaderprogram, 0, "outColor")

glLinkProgram(shaderprogram)
glUseProgram(shaderprogram)

posattrib = glGetAttribLocation(shaderprogram, "position")
glVertexAttribPointer(posattrib, 2, GL_FLOAT, GL_FALSE, 5*sizeof(Float32), C_NULL)
glEnableVertexAttribArray(posattrib)

colattrib = glGetAttribLocation(shaderprogram, "color")
glVertexAttribPointer(colattrib, 3, GL_FLOAT, GL_FALSE, 5*sizeof(Float32), Ptr{Void}(2*sizeof(Float32)))
glEnableVertexAttribArray(colattrib)

unicolor = glGetUniformLocation(shaderprogram, "triangleColor")

function render()
  glUniform3f(unicolor, 0.5(sin(time())+1.0), 0.0, 0.0)
  glDrawArrays(GL_TRIANGLES, 0, length(vertices))
end

c = Condition()

@async while !GLFW.WindowShouldClose(window)
  render()
  GLFW.SwapBuffers(window)
  GLFW.PollEvents()
  if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
    GLFW.SetWindowShouldClose(window, true)
    notify(c)
  end
  yield()
end

begin
  wait(c)
  yield()
  GLFW.DestroyWindow(window)
end
