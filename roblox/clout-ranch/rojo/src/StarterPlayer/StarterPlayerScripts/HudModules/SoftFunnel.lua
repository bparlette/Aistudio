--!strict
-- DEPRECATED — SoftOffer.lua is the sole SoftOffer remote modal owner.
-- Kept as a no-op stub so accidental require/mount cannot double-listen / double-modal.
-- Do not re-add OnClientEvent for Remotes.SoftOffer here.

local SoftFunnel = {}

export type Handle = {
	Show: (self: Handle, payload: any) -> (),
	Hide: (self: Handle) -> (),
	Destroy: (self: Handle) -> (),
}

--- No-op. SoftOffer.mount owns the funnel UI.
function SoftFunnel.mount(_root: Frame, _onToast: ((string, string?) -> ())?, _parentMaid: any?): Handle
	warn("[CloutRanch] SoftFunnel.mount is deprecated — SoftOffer is sole funnel modal owner")
	local handle: Handle = {
		Show = function(_self, _payload: any) end,
		Hide = function(_self) end,
		Destroy = function(_self) end,
	}
	return handle
end

return SoftFunnel
