cmake_minimum_required(VERSION 3.20)
project(Dock LANGUAGES CXX RC)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 便携版：静态 CRT（代价是体积略大、无法共享 CRT 安全更新）
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

add_executable(Dock WIN32 src/main.cpp dock.rc)
# 图标文件变化时强制重新编译资源
set_source_files_properties(dock.rc PROPERTIES OBJECT_DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/app.ico")

target_compile_definitions(Dock PRIVATE
    UNICODE _UNICODE NOMINMAX WIN32_LEAN_AND_MEAN)

target_link_libraries(Dock PRIVATE
    d3d11 dxgi d2d1 dcomp dwmapi shell32 ole32 user32 gdi32)

if (MSVC)
    target_link_options(Dock PRIVATE "/MANIFESTINPUT:${CMAKE_CURRENT_SOURCE_DIR}/dock.manifest")
    target_compile_options(Dock PRIVATE /W4 /permissive- /utf-8 /EHsc)
    # Release 优化
    target_compile_options(Dock PRIVATE $<$<CONFIG:Release>:/O2 /GL>)
    target_link_options(Dock PRIVATE $<$<CONFIG:Release>:/LTCG /OPT:REF /OPT:ICF>)
endif()