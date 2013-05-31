decision_var_names = {"x_p2s2", "x_p2s3"}

-- All of our vectors have 6 elements (5 decision vars and 1 RHS)
-- The coefficients are the values in the arrays

-- Initial objective
obj = {1, 1, 0, 0, 0, 0}

-- Our constraints are vectors with the addition of a RHS
c1 = {1, 1, 1, 0, 0, 1}
c2 = {1, 0, 0, -1/13, 0, 9/13}
c3 = {0, 1, 0, 0, -1/13, 4/13}


-- Assuming vectors are the same length
function add_vectors(v1, v2, v2_scalar)
	local result = {}
	for i = 1, #v1 do
		result[i] = v1[i] + v2_scalar * v2[i]
	end
	return result
end

function print_tableau(tableau)
	for r = 1, #tableau do
		line = ""
		for v = 1, #tableau[r] do
			if (tableau[r][v] == 0) then
				line = line .. string.format("%9s", "--")
			else
				line = line .. string.format("%9.4f", tableau[r][v])
			end
		end
		print(line)
	end
end

function check_strong_optimality(tableau)
	local obj = tableau[#tableau]
	for i = 1, #obj-1 do
		if (obj[i] > 0) then
			-- Can potentially improve objective
			return false
		end
	end

	-- If we got here, then all of the objective coefficients are
	-- nonpositive, and there's no way to improve the objective
	return true
end

function get_potential_pivots(tableau, nonbasic_vars)
	local obj = tableau[#tableau]

	-- See if any of the nonbasic vars have positive objective coeffs
	local potential_pivots = {}
	for _, v in pairs(nonbasic_vars) do
		if (obj[v] > 0) then
			potential_pivots[#potential_pivots+1] = v
		end
	end

	-- See if there's a constraint we can pivot in
	local potential_pivots = {}
	for c = 1, #tableau-1 do
		local rhs = tableau[c][#obj]
		for _, v in pairs(potential_pivots) do
			if (rhs > 0) then
				potential_pivots[#potential_pivots+1] = {constraint = c, var = v}
			end
		end
	end
	return potential_pivots
end

-- Eliminate x1 from c1
c1 = add_vectors(c1, c2, -1)

-- Eliminate x2 from c1
c1 = add_vectors(c1, c3, -1)

-- Can we eliminate x1 and x2 from the objective?
obj = add_vectors(obj, c2, -1)
obj = add_vectors(obj, c3, -1)

--[
--  At this point, we're in canonical form and can start applying the simplex.
--  Let's walk through this step-by-step to see what happens.
--]

-- The basis shows the current basis variables. The order of the elements
-- reflects the constraint order.
basis = {3, 1, 2}
non_basis = {4, 5}

-- The tableau is the problem that we're solving
tableau = {c1, c2, c3, obj}

print_tableau(tableau)

-- Check optimality
print(string.format("Is strong optimal? %s", check_strong_optimality(tableau)))

-- Check potential pivots
print(string.format("Num potential pivots: %d", #get_potential_pivots(tableau, non_basis)))


-- Optimum is x1 = 0.6923, x2 = 0.3077
