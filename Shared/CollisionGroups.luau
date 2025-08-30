---# SERVICES #---
local PhysicsService = game:GetService("PhysicsService")

---# MODULES #---
local Output = require(script.Parent.Output)

---# VARIABLES #---
local IsClient = game:GetService("RunService"):IsClient()

---# SCRIPT #---
local module = {}

function module:CreateCollisionGroup(GroupName : string)
	Output.ErrorAssert(IsClient,"Client can't use this function!")
	Output.ErrorAssert(not GroupName,"Didn't got a group name for the collision group!")
	Output.ErrorAssert(typeof(GroupName) ~= "string","Group Name is not a string")
	Output.ErrorAssert(PhysicsService:IsCollisionGroupRegistered(GroupName),"This group is already registered, can't be registered twice.")

	PhysicsService:RegisterCollisionGroup(GroupName)
end

function module:DeleteCollisionGroup(GroupName : string)
	Output.ErrorAssert(IsClient,"Client can't use this function!")
	Output.ErrorAssert(not GroupName,"Didn't got a group name for the collision group!")
	Output.ErrorAssert(typeof(GroupName) ~= "string","Group Name is not a string")
	Output.ErrorAssert(not PhysicsService:IsCollisionGroupRegistered(GroupName),"This group is not yet registered, can't unregister.")

	PhysicsService:UnregisterCollisionGroup(GroupName)
end

function module:EnableCollisions(Group1 : string, Group2 : string)
	Output.ErrorAssert(IsClient,"Client can't use this function!")
	Output.ErrorAssert(not Group1,"Didn't got first group name to enable collisions!")
	Output.ErrorAssert(not Group2,"Didn't got second group name to enable collisions!")
	Output.ErrorAssert(typeof(Group1) ~= "string","First group name is not a string")
	Output.ErrorAssert(typeof(Group2) ~= "string","Second group name is not a string")
	Output.ErrorAssert(not PhysicsService:IsCollisionGroupRegistered(Group1),"First group is not yet registered.")
	Output.ErrorAssert(not PhysicsService:IsCollisionGroupRegistered(Group2),"Second group is not yet registered.")
	
	PhysicsService:CollisionGroupSetCollidable(Group1,Group2,true)
end

function module:DisableCollisions(Group1 : string, Group2 : string)
	Output.ErrorAssert(IsClient,"Client can't use this function!")
	Output.ErrorAssert(not Group1,"Didn't got first group name to enable collisions!")
	Output.ErrorAssert(not Group2,"Didn't got second group name to enable collisions!")
	Output.ErrorAssert(typeof(Group1) ~= "string","First group name is not a string")
	Output.ErrorAssert(typeof(Group2) ~= "string","Second group name is not a string")
	Output.ErrorAssert(not PhysicsService:IsCollisionGroupRegistered(Group1),"First group is not yet registered.")
	Output.ErrorAssert(not PhysicsService:IsCollisionGroupRegistered(Group2),"Second group is not yet registered.")

	PhysicsService:CollisionGroupSetCollidable(Group1,Group2,false)
end

function module:AddToCollisionGroup(Object : BasePart | Model, GroupName : string)
	Output.ErrorAssert(not Object,"Didn't got object to add to collision group!")
	Output.ErrorAssert(not GroupName,"Didn't got group name!")
	Output.ErrorAssert(typeof(Object) ~= "Instance","Object is not an instance")
	Output.ErrorAssert(typeof(GroupName) ~= "string","Group Name is not a string")
	Output.ErrorAssert(not PhysicsService:IsCollisionGroupRegistered(GroupName),"Group is not yet registered.")
	
	if Object:IsA("BasePart") then
		Object.CollisionGroup = GroupName
	elseif Object:IsA("Model") then
		for _,Part in Object:GetDescendants() do
			if not Part:IsA("BasePart") then continue end
			
			Part.CollisionGroup = GroupName
		end
	end
end

return (module) :: typeof(module)