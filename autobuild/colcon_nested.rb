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

module Autobuild
    def self.colcon_nested(options, &block)
        ColconNested.new(options, &block)
    end

    class ColconNested < Autobuild::Colcon
        attr_accessor :parent_pkg

        def update_srcdir
            super
            @importdir = File.join(parent_pkg.importdir, "banana")
        end

        def import(options)
            result = parent_pkg.import(options)
            update_srcdir

            return result if parent_pkg.failed? || File.directory?(srcdir)
            raise Autoproj::PackageNotFound,
                  "#{name} not found within #{parent_pkg.name}"
        end
    end
end
