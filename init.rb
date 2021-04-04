# Copyright 2021 Open Rise Robotics
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ws = Autoproj.workspace

ws.config.declare 'ros_distro', 'string',
            default: 'foxy',
            doc: [ "Which ros distro do you want?" ]

ROS_DISTRO = ws.config.get('ros_distro',nil)

Autoproj.config.separate_prefixes = true
Autobuild::CMake.delete_obsolete_files_in_prefix = Autoproj.config.separate_prefixes?

ROS_DISTRO_PATH = File.join('/opt', 'ros', ROS_DISTRO)

Autoproj.env_set 'ROS_ROOT', File.join(ROS_DISTRO_PATH, 'share', 'ros')
Autoproj.env_set 'ROS_DISTRO', ROS_DISTRO
Autoproj.env_set 'ROS_ETC_DIR', File.join(ROS_DISTRO_PATH, 'etc', 'ros')
Autoproj.env_add_path 'CMAKE_PREFIX_PATH', ROS_DISTRO_PATH
Autoproj.env_add_path 'PYTHONPATH', File.join(ROS_DISTRO_PATH, 'lib', 'python', 'PYTHON_VERSION', 'dist-packages')
Autoproj.env_add_path 'PATH', File.join(ROS_DISTRO_PATH, 'bin')
Autoproj.env_add_path 'LD_LIBRARY_PATH', File.join(ROS_DISTRO_PATH, 'lib')
Autoproj.env_add_path 'PKG_CONFIG_PATH', File.join(ROS_DISTRO_PATH, 'lib', 'pkgconfig')
Autoproj.env_add_path 'ROS_PACKAGE_PATH', File.join(ROS_DISTRO_PATH, 'share')
Autoproj.env_add_path 'COLCON_CURRENT_PREFIX', Autoproj.prefix

Autobuild::CMake.prefix_path << ROS_DISTRO_PATH

Autoproj.config.set('build', File.join(Autoproj.root_dir, 'build')) unless Autoproj.config.get('build', nil)
Autoproj.config.set('source', 'src') unless Autoproj.config.source_dir
Autoproj.config.set('USE_PYTHON', 'YES') unless Autoproj.config.get('USE_PYTHON', nil)

(['sh'] + Autoproj.config.user_shells).each do |shell|
  shell_helper = "setup.#{shell}"
  Autoproj.env_source_after(File.join(ROS_DISTRO_PATH, shell_helper), shell: shell) if File.join(ROS_DISTRO_PATH, shell_helper)
end

(['sh'] + Autoproj.config.user_shells).each do |shell|
  shell_helper = "setup.#{shell}"
  FileUtils.touch File.join(Autoproj.prefix, shell_helper)
  Autoproj.env_source_after(File.join(Autoproj.prefix, shell_helper), shell: shell)
end

require_relative 'autobuild/ament'
require_relative 'autobuild/ament_nested'
require_relative 'autobuild/colcon'
require_relative 'autobuild/colcon_nested'
require_relative 'autobuild/dsl'
