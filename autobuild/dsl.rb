# Copyright 2021 Open Rise Robotics Modification
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

def ament_package_setup(pkg)
    pkg.update_srcdir
    pkg.post_import do
        test_dir = File.join(pkg.srcdir, 'test')
        if File.directory?(test_dir)
            pkg.test_utility.source_dir = File.join(pkg.builddir, 'test_results', pkg.name)
            pkg.define 'BUILD_TESTING', pkg.test_utility.enabled?
        end
    end

    common_make_based_package_setup(pkg)
    pkg.define 'CMAKE_EXPORT_COMPILE_COMMANDS', 'ON'
    pkg.use_package_xml = true
end

def ament_cmake_package(name, workspace: Autoproj.workspace)
    package_common(:ament_cmake, name, workspace: workspace) do |pkg|
        ament_package_setup(pkg)
        yield(pkg) if block_given?
    end
end

def ament_cmake_nested_package(name, parent_pkg, workspace: Autoproj.workspace)
    package_common(:ament_cmake_nested, name, workspace: workspace) do |pkg|
        pkg.parent_pkg = parent_pkg
        ament_package_setup(pkg)
        yield(pkg) if block_given?
    end

    current_set = Autoproj.current_package_set
    vcs_entry = current_set.importer_definition_for(parent_pkg.name).to_hash
    current_set.add_version_control_entry(name, vcs_entry)
end

def ament_cmake_metapackage(name, *packages)
    ament_cmake_package(name)
    packages.each do |nested_pkg_name|
        ament_cmake_nested_package(nested_pkg_name, package(name))
        package(name).depends_on nested_pkg_name
        move_package(nested_pkg_name, name)
    end
end

def colcon_package(name, workspace: Autoproj.workspace)
  package_common(:colcon, name, workspace: workspace) do |pkg| 
    pkg.use_package_xml = true
    pkg.update_srcdir
    pkg.post_import do
      test_dir = File.join(pkg.srcdir, 'test')
      if File.directory?(test_dir)
          pkg.test_utility.source_dir = File.join(pkg.builddir, 'test_results', pkg.name)
      end
    end
    yield(pkg) if block_given?
  end
end

def colcon_nested_package(name, parent_pkg, workspace: Autoproj.workspace)
  package_common(:colcon_nested, name, workspace: workspace) do |pkg|
    pkg.use_package_xml = true
    pkg.update_srcdir
    pkg.parent_pkg = parent_pkg
    yield(pkg) if block_given?
  end

  current_set = Autoproj.current_package_set
  vcs_entry = current_set.importer_definition_for(parent_pkg.name).to_hash
  current_set.add_version_control_entry(name, vcs_entry)
end

def colcon_metapackage(name, *packages)
  colcon_package(name)
  packages.each do |nested_pkg_name|
    colcon_nested_package(nested_pkg_name, package(name))
    package(name).depends_on nested_pkg_name
    move_package(nested_pkg_name, name)
  end
end

def ament_python(name, workspace: Autoproj.workspace)
  package_common(:python_setuptools, name, workspace: workspace) do |pkg|
      Autoproj.env_add_path 'AMENT_PREFIX_PATH', pkg.prefix
      pkg.use_package_xml = true
      yield(pkg) if block_given?
  end
end
