local Path = require("plenary/path")
local Config = {}
Config.__index = Config

function Config:validate()
  vim.validate {
    neuron_dir = {self.neuron_dir, 'string'},
    mappings = {self.mappings, 'boolean'},
    virtual_titles = {self.virtual_titles, 'boolean'},
    run = {self.run, 'function'},
    leader = {self.leader, 'string'},
  }
  if not Path:new(self.path):exists() then
    error(string.format("The path supplied for the neuron_dir does not exist"))
  end
end

function Config:extend(user_config)
  for k, v in pairs(user_config) do self[k] = v end
  self:validate()
end

function Config:after_extend()
  self.neuron_dir = vim.fn.expand(self.neuron_dir)
end

function Config:setup(user_config)
  self:extend(user_config)
  self:after_extend()
end

return setmetatable({
  neuron_dir = "~/neuron",
  mappings = true, -- to set default mappings
  virtual_titles = true, -- set virtual titles
  run = function() end, -- custom code to run
  leader = "gz", -- the leader key to for all mappings
}, Config)
