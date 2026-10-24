#pragma once
#include "SysUtils.h"

class VulkanHooks
{
  public:
    static void Hook(HMODULE vulkan1);
    static void Unhook();
};
