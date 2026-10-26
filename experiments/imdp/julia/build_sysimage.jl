# Build intervalmdp.so, a sysimage containing IntervalMDP.jl with the code that
# check_intervalmdp.jl needs already compiled (see precompile.jl). scripts/intervalmdp.sh
# uses it if present, so that the runs do not measure Julia compiling the solver.
#
# Run from experiments/imdp/ with
#   bin/julia julia/build_sysimage.jl
# PackageCompiler.jl is installed into a temporary environment, not into julia/.
# The sysimage is compiled for the CPU targets of Julia's own sysimage, so that it
# runs wherever Julia does; PackageCompiler's default, the CPU of the build machine,
# fails on other machines with "Unable to find compatible target in cached code image".
import Pkg
here = @__DIR__
Pkg.activate(; temp=true)
Pkg.add(name="PackageCompiler", version="2")
using PackageCompiler

create_sysimage(["IntervalMDP"];
                project=here,
                sysimage_path=joinpath(here, "intervalmdp.so"),
                cpu_target="sysimage",
                precompile_execution_file=joinpath(here, "precompile.jl"))
