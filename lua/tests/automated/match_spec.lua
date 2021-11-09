local utils = require("neuron/utils")

local eq = function(a, b) assert.are.same(a, b) end

describe("link match", function()
  it("should match folgezettel", function()
    local link = "[[[adf8sda7]]]"
    local id = utils.match_link(link)
    eq("adf8sda7", id)
  end)

  it("should match zettel", function()
    local link = "[[fdsk4590]]"
    local id = utils.match_link(link)
    eq("fdsk4590", id)
  end)

  it("should deal with not enough letters", function()
    local link = "[[fd]]"
    local id = utils.match_link(link)
    eq("fd", id)
  end)

  it("should deal with alt name", function()
    local line = "- [[ID1|my alt id 1]] [[ID2|my alt id 2]]  [[fdsk4590]]"
    local pos = line:find("my alt id 2") + 2
    local id = utils.match_link_from_line(line, pos)
    eq("ID2", id)
  end)

  -- it('should be okay with edge cases', function()
  --   local link = '[[fdsk4590]]]'
  --   local id = utils.match_link(link)
  --   eq("fdsk4590", id)
  -- end)
end)
