# Install IntervalMDP 0.7 in your Julia environment before running this script.
using IntervalMDP
using IntervalMDP.Data

usage = "Usage: julia --project=ENV check_intervalmdp.jl [--precision EPS] PATH_WITHOUT_EXTENSION"
# Value iteration stops once the largest change of a value is below the precision (absolute).
tolerance = 1e-6
if length(ARGS) == 3 && ARGS[1] == "--precision"
    tolerance = parse(Float64, ARGS[2])
elseif length(ARGS) != 1
    error(usage)
end
base = last(ARGS)
property = strip(read(base * ".pctl", String))
# startswith(property, "Pmaxmin") || error(
#     "This runner supports reachability/reach-avoid exports. " *
#     "IntervalMDP.jl's importer does not support reachability-reward queries; use Storm or PRISM for those.",
# )

# The importer always uses a precision of 1e-6 for unbounded properties; replace it.
function with_precision(problem, precision)
    spec = specification(problem)
    prop = system_property(spec)
    if prop isa InfiniteTimeReachability
        prop = InfiniteTimeReachability(reach(prop), precision)
    elseif prop isa InfiniteTimeReachAvoid
        prop = InfiniteTimeReachAvoid(reach(prop), avoid(prop), precision)
    end
    spec = Specification(prop, satisfaction_mode(spec), strategy_mode(spec))
    return ControlSynthesisProblem(system(problem), spec)
end

println("setup done")
# Julia's startup and compilation dominate small models, so time the steps themselves.
read_time = @elapsed (problem = with_precision(read_prism_file(base), tolerance))
println("read file")
solve_time = @elapsed (solution = solve(problem))
println("solved it!")
values = value_function(solution)
for state in initial_states(system(problem))
    println("Initial state ", state - 1, ": ", values[state])
end
println("Iterations: ", num_iterations(solution))
println("Maximum Bellman residual: ", maximum(abs, residual(solution)))
println("Time for reading: ", read_time, "s")
println("Time for solving: ", solve_time, "s")
