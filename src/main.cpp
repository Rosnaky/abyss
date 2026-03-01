#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include "cuda_interop.h"

static const char* vertexShaderSource = R"(
#version 450 core

out vec2 uv;

void main()
{
    // 3 vertices of an oversized triangle from gl_VertexID
    vec2 positions[3] = vec2[](
        vec2(-1.0, -1.0),
        vec2( 3.0, -1.0),
        vec2(-1.0,  3.0)
    );

    gl_Position = vec4(positions[gl_VertexID], 0.0, 1.0);
    uv = positions[gl_VertexID] * 0.5 + 0.5;
}
)";

static const char* fragmentShaderSource = R"(
#version 450 core

in vec2 uv;
out vec4 fragColor;

uniform sampler2D screenTexture;

void main()
{
    fragColor = texture(screenTexture, uv);
}
)";

static GLuint compileShader(GLenum type, const char *source) {
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);

    GLint success;
    char log[512];
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);

    if (!success) {
        std::cerr << "Shader compilation failed for " << type << std::endl;
        glGetShaderInfoLog(shader, sizeof(log), nullptr, log);
    }
    return shader;
}

static GLuint createProgram(const char *vertSrc, const char *fragSrc) {
    GLuint vert = compileShader(GL_VERTEX_SHADER, vertSrc);
    GLuint frag = compileShader(GL_FRAGMENT_SHADER, fragSrc);

    GLuint program = glCreateProgram();
    glAttachShader(program, vert);
    glAttachShader(program, frag);
    glLinkProgram(program);

    GLint success;
    char log[512];
    glGetProgramiv(program, GL_LINK_STATUS, &success);
    
    if (!success) {
        std::cerr << "Create program failed" << std::endl;
        glGetProgramInfoLog(program, sizeof(log), NULL, log);
    }

    glDeleteShader(vert);
    glDeleteShader(frag);
    return program;
}

static void framebuffer_size_callback(GLFWwindow* window, int width, int height) {
    glViewport(0, 0, width, height);
}

int main() {
    
    if (glfwInit() == GLFW_FALSE) {
        std::cerr << "An error has occured with glfwInit()" << std::endl;
        return 1;
    }
    
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 5);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow *window = glfwCreateWindow(1280, 720, "Abyss", nullptr, nullptr);
    if (!window) {
        std::cerr << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return 1;
    }

    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)) {
        std::cerr << "Failed to initialize glad" << std::endl;
    }

    std::cout << "OpenGL " << glGetString(GL_VERSION) << std::endl;

    // Vertex Array
    GLuint program = createProgram(vertexShaderSource, fragmentShaderSource);

    GLuint emptyVAO;
    glGenVertexArrays(1, &emptyVAO);

    // Textures
    GLuint screenTex;
    glGenTextures(1, &screenTex);
    glBindTexture(GL_TEXTURE_2D, screenTex);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, 1280, 720, 0, GL_RGBA, GL_FLOAT, nullptr);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glBindTexture(GL_TEXTURE_2D, 0);

    // Cuda
    initCudaInterop(screenTex);

    while (!glfwWindowShouldClose(window)) {
        if (glfwGetKey(window, GLFW_KEY_ESCAPE)) {
            glfwSetWindowShouldClose(window, true);
        }

        glClearColor(0, 0, 0, 1);
        glClear(GL_COLOR_BUFFER_BIT);

        renderFrame(1280, 720, static_cast<float>(glfwGetTime()));
        glUseProgram(program);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, screenTex);
        glBindVertexArray(emptyVAO);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    cleanupCudaInterop();
    glDeleteTextures(1, &screenTex);
    glDeleteVertexArrays(1, &emptyVAO);
    glDeleteProgram(program);
    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
