local fly = {}

function fly.new()
	local self = setmetatable({}, fly)
	
	self._Players = self:_GetService("Players")
	self._RunService = self:_GetService("RunService")
	self._UserInputService = self:_GetService("UserInputService")
	
	self._localPlayer = self._Players.LocalPlayer
	self._character = self._localPlayer.Character or self._localPlayer.CharacterAdded:Wait()
	self._humanoid = self._character:WaitForChild("Humanoid")
	self._rootPart = self._character:WaitForChild("HumanoidRootPart")
	self._animator = self._humanoid:WaitForChild("Animator")
	
	self._currentCamera = workspace.CurrentCamera
	

	self.CONTROL_MODULE = require(self._localPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("ControlModule"))

	assert(self.CONTROL_MODULE, "ControlModule not found, fatal error")

	self._state = false
	self._speed = 1

	self._rotation = {
		useX = false,
		useY = false,
		useZ = false,

		X = CFrame.Angles(math.rad(180), 0, 0),
		Y = CFrame.Angles(0, math.rad(180), 0),
		Z = CFrame.Angles(0, 0, math.rad(180)),
	}

	self._smoothness = 1200
	self._controlsUpAndDown = {Up = 0, Down = 0}
	self._usePlatformStand = true
	self._useKeyBindToggle = false

	self._keyBindings = {
		Up = Enum.KeyCode.E,
		Down = Enum.KeyCode.Q,
		EnableFly = Enum.KeyCode.F,
	}

	self.BodyVelocity = Instance.new("BodyVelocity")
	self.BodyGyro = Instance.new("BodyGyro")

	self.ControlsUpAndDownBeganConn = self._UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if self._useKeyBindToggle then
			if typeof(self._keyBindings.EnableFly) == "EnumItem" and input.KeyCode == self._keyBindings.EnableFly then
				self:Set(not self._state)
			end
		end

		if input.KeyCode == self._keyBindings.Up then
			self._controlsUpAndDown.Up = 1
		elseif input.KeyCode == self._keyBindings.Down then
			self._controlsUpAndDown.Down = 1
		end
	end)

	self.ControlsUpAndDownEndedConn = self._UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == self._keyBindings.Up then
			self._controlsUpAndDown.Up = 0
		elseif input.KeyCode == self._keyBindings.Down then
			self._controlsUpAndDown.Down = 0
		end
	end)

	return self
end

function fly:_GetService(service: string): any
	if typeof(service) ~= "string" then return end

	local cloneref = (cloneref or clonereference or function(instance: any)
		return instance
	end)

	local success, cache = pcall(function()
		return cloneref(game:GetService(service))
	end)

	if success then
		return cache
	else
		error("Invalid Service: " .. tostring(service))
	end
end

function fly:ApplyAndUpdateGyroAndVelocity()
	if typeof(self.BodyVelocity) ~= "Instance" or not self.BodyVelocity:IsA("BodyVelocity") or not self.BodyVelocity:IsDescendantOf(game) then
		self.BodyVelocity = Instance.new("BodyVelocity") 
	end 
	if typeof(self.BodyGyro) ~= "Instance" or not self.BodyGyro:IsA("BodyGyro") or not self.BodyGyro:IsDescendantOf(game) then
		self.BodyGyro = Instance.new("BodyGyro") 
	end

	if not self._state then
		self.BodyVelocity.Parent = nil
		self.BodyGyro.Parent = nil
		return 
	end 

	if self.BodyVelocity and self.BodyVelocity.Parent ~= self._rootPart then
		self.BodyVelocity.Parent = self._rootPart
	end

	if self.BodyGyro and self.BodyGyro.Parent ~= self._rootPart then
		self.BodyGyro.Parent = self._rootPart
	end 

end

function fly:_GetSpeed(): number
	return self._speed * 35
end

function fly:GetSpeed(): number
	return self._speed
end

function fly:GetKeyBindToEnableFly(): Enum.KeyCode
	return self._keyBindings.EnableFly
end

function fly:UseKeyBindToEnableFly(bool: boolean)
	self._useKeyBindToggle = bool
end

function fly:SetKeyBindToEnableFly(keyCode: Enum.KeyCode | string)
	if typeof(keyCode) ~= "EnumItem"  then
		self._keyBindings.EnableFly = keyCode
	elseif typeof(keyCode) == "string" then 
		self._keyBindings.EnableFly = Enum.KeyCode[keyCode]
	end
end


function fly:SetValueOfAxis(axis, value)
	if typeof(value) ~= "number" then return end
	if typeof(axis) ~= "string" then return end

	axis = string.upper(axis)

	if axis == "X" then
		self._rotation.X = CFrame.Angles(math.rad(value), 0, 0)
	elseif axis == "Y" then
		self._rotation.Y = CFrame.Angles(0, math.rad(value), 0)
	elseif axis == "Z" then
		self._rotation.Z = CFrame.Angles(0, 0, math.rad(value))
	end
end

function fly:_GetRotationForGryo(): CFrame

	local rotation = self._currentCamera.CFrame or workspace.CurrentCamera.CFrame

	if self._rotation.useX then
		rotation *= self._rotation.X
	end

	if self._rotation.useY then
		rotation *= self._rotation.Y
	end

	if self._rotation.useZ then
		rotation *= self._rotation.Z
	end

	return rotation
end

function fly:Set(value: boolean, speed: number?)
	if typeof(value) ~= "boolean" then return end

	if typeof(speed) == "number" then
		self._speed = speed
	end

	if self._state == value then return end

	self._state = value

	self:ApplyAndUpdateGyroAndVelocity()

	if not value then
		return
	end

	task.spawn(function()
		while self._state do

			task.wait()

			if not self._character then return end

			if self._usePlatformStand then
				if self._humanoid then self._humanoid.PlatformStand = true end
			else
				if self._humanoid then self._humanoid.PlatformStand = false end
			end

			self:ApplyAndUpdateGyroAndVelocity()

			local moveVector = self.CONTROL_MODULE:GetMoveVector()

			local direction = (self._currentCamera or workspace.CurrentCamera).CFrame.RightVector * moveVector.X - (self._currentCamera or workspace.CurrentCamera).CFrame.LookVector * moveVector.Z
			local up = self._controlsUpAndDown.Up - self._controlsUpAndDown.Down

			self.BodyVelocity.Velocity = direction * self:_GetSpeed() + Vector3.new(0, up * self:_GetSpeed(), 0)
			self.BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

			self.BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			self.BodyGyro.P = 9e4
			self.BodyGyro.D = self._smoothness

			self.BodyGyro.CFrame = self:_GetRotationForGryo()
		end

		if self._humanoid then self._humanoid.PlatformStand = false end
		self:ApplyAndUpdateGyroAndVelocity()
	end)
end

function fly:SetSpeed(value: number)
	if typeof(value) ~= "number" then return end
	self._speed = value
end

function fly:SetAxisEnabled(axis: string, value: boolean)
	if typeof(value) ~= "boolean" then return end
	if typeof(axis) ~= "string" then return end

	axis = string.upper(axis)

	if axis == "X" then
		self._rotation.useX = value
	elseif axis == "Y" then
		self._rotation.useY = value
	elseif axis == "Z" then
		self._rotation.useZ = value
	end

end


function fly:SetSmoothness(value: number)
	if typeof(value) ~= "number" then return end
	self._smoothness = value
end

function fly:GetSmoothness(): number
	return self._smoothness
end

function fly:UsePlatformStand(value: boolean)
	if typeof(value) ~= "boolean" then return end
	self._usePlatformStand = value
end

function fly:GetPlatformStand(): boolean
	return self._usePlatformStand
end

function fly:DisableAllAxis()
	self._rotation.useX = false
	self._rotation.useY = false
	self._rotation.useZ = false
end

return fly.new()
