module vulkan_experiments.helper;

import krepel.image;

import vulkan;
import krepel.log;

private import std.string : fromStringz;


FunctionType LoadInstanceFunction(FunctionType)(typeof(vkGetInstanceProcAddr) GetInstanceProcAddr,
                                                VkInstance Instance,
                                                const(char)* FunctionName,
                                                FunctionType FallbackInCaseOfFailure)
{
  auto Func = GetInstanceProcAddr(Instance, FunctionName);
  if(Func is null)
  {
    Log.Warning("Failed to load Vulkan instance procedure: %s", FunctionName.fromStringz);
    return FallbackInCaseOfFailure;
  }

  return cast(FunctionType)Func;
}

FunctionType LoadDeviceFunction(FunctionType)(typeof(vkGetDeviceProcAddr) GetDeviceProcAddr,
                                              VkDevice Device,
                                              const(char)* FunctionName,
                                              FunctionType FallbackInCaseOfFailure)
{
  auto Func = GetDeviceProcAddr(Device, FunctionName);
  if(Func is null)
  {
    Log.Warning("Failed to load Vulkan device procedure: %s", FunctionName.fromStringz);
    return FallbackInCaseOfFailure;
  }

  return cast(FunctionType)Func;
}

// Uses the current global functions as fallback.
void LoadAllInstanceFunctions(typeof(vkGetInstanceProcAddr) GetInstanceProcAddr,
                              VkInstance Instance)
{
  assert(GetInstanceProcAddr);
  assert(Instance);


  vkAcquireNextImageKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkAcquireNextImageKHR".ptr, .vkAcquireNextImageKHR);
  vkAllocateCommandBuffers = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkAllocateCommandBuffers".ptr, .vkAllocateCommandBuffers);
  vkAllocateDescriptorSets = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkAllocateDescriptorSets".ptr, .vkAllocateDescriptorSets);
  vkAllocateMemory = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkAllocateMemory".ptr, .vkAllocateMemory);
  vkBeginCommandBuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkBeginCommandBuffer".ptr, .vkBeginCommandBuffer);
  vkBindBufferMemory = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkBindBufferMemory".ptr, .vkBindBufferMemory);
  vkBindImageMemory = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkBindImageMemory".ptr, .vkBindImageMemory);
  vkCmdBeginQuery = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdBeginQuery".ptr, .vkCmdBeginQuery);
  vkCmdBeginRenderPass = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdBeginRenderPass".ptr, .vkCmdBeginRenderPass);
  vkCmdBindDescriptorSets = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdBindDescriptorSets".ptr, .vkCmdBindDescriptorSets);
  vkCmdBindIndexBuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdBindIndexBuffer".ptr, .vkCmdBindIndexBuffer);
  vkCmdBindPipeline = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdBindPipeline".ptr, .vkCmdBindPipeline);
  vkCmdBindVertexBuffers = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdBindVertexBuffers".ptr, .vkCmdBindVertexBuffers);
  vkCmdBlitImage = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdBlitImage".ptr, .vkCmdBlitImage);
  vkCmdClearAttachments = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdClearAttachments".ptr, .vkCmdClearAttachments);
  vkCmdClearColorImage = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdClearColorImage".ptr, .vkCmdClearColorImage);
  vkCmdClearDepthStencilImage = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdClearDepthStencilImage".ptr, .vkCmdClearDepthStencilImage);
  vkCmdCopyBuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdCopyBuffer".ptr, .vkCmdCopyBuffer);
  vkCmdCopyBufferToImage = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdCopyBufferToImage".ptr, .vkCmdCopyBufferToImage);
  vkCmdCopyImage = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdCopyImage".ptr, .vkCmdCopyImage);
  vkCmdCopyImageToBuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdCopyImageToBuffer".ptr, .vkCmdCopyImageToBuffer);
  vkCmdCopyQueryPoolResults = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdCopyQueryPoolResults".ptr, .vkCmdCopyQueryPoolResults);
  vkCmdDispatch = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdDispatch".ptr, .vkCmdDispatch);
  vkCmdDispatchIndirect = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdDispatchIndirect".ptr, .vkCmdDispatchIndirect);
  vkCmdDraw = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdDraw".ptr, .vkCmdDraw);
  vkCmdDrawIndexed = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdDrawIndexed".ptr, .vkCmdDrawIndexed);
  vkCmdDrawIndexedIndirect = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdDrawIndexedIndirect".ptr, .vkCmdDrawIndexedIndirect);
  vkCmdDrawIndirect = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdDrawIndirect".ptr, .vkCmdDrawIndirect);
  vkCmdEndQuery = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdEndQuery".ptr, .vkCmdEndQuery);
  vkCmdEndRenderPass = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdEndRenderPass".ptr, .vkCmdEndRenderPass);
  vkCmdExecuteCommands = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdExecuteCommands".ptr, .vkCmdExecuteCommands);
  vkCmdFillBuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdFillBuffer".ptr, .vkCmdFillBuffer);
  vkCmdNextSubpass = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdNextSubpass".ptr, .vkCmdNextSubpass);
  vkCmdPipelineBarrier = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdPipelineBarrier".ptr, .vkCmdPipelineBarrier);
  vkCmdPushConstants = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdPushConstants".ptr, .vkCmdPushConstants);
  vkCmdResetEvent = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdResetEvent".ptr, .vkCmdResetEvent);
  vkCmdResetQueryPool = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdResetQueryPool".ptr, .vkCmdResetQueryPool);
  vkCmdResolveImage = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdResolveImage".ptr, .vkCmdResolveImage);
  vkCmdSetBlendConstants = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdSetBlendConstants".ptr, .vkCmdSetBlendConstants);
  vkCmdSetDepthBias = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdSetDepthBias".ptr, .vkCmdSetDepthBias);
  vkCmdSetDepthBounds = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdSetDepthBounds".ptr, .vkCmdSetDepthBounds);
  vkCmdSetEvent = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdSetEvent".ptr, .vkCmdSetEvent);
  vkCmdSetLineWidth = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdSetLineWidth".ptr, .vkCmdSetLineWidth);
  vkCmdSetScissor = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdSetScissor".ptr, .vkCmdSetScissor);
  vkCmdSetStencilCompareMask = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdSetStencilCompareMask".ptr, .vkCmdSetStencilCompareMask);
  vkCmdSetStencilReference = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdSetStencilReference".ptr, .vkCmdSetStencilReference);
  vkCmdSetStencilWriteMask = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdSetStencilWriteMask".ptr, .vkCmdSetStencilWriteMask);
  vkCmdSetViewport = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdSetViewport".ptr, .vkCmdSetViewport);
  vkCmdUpdateBuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdUpdateBuffer".ptr, .vkCmdUpdateBuffer);
  vkCmdWaitEvents = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdWaitEvents".ptr, .vkCmdWaitEvents);
  vkCmdWriteTimestamp = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCmdWriteTimestamp".ptr, .vkCmdWriteTimestamp);
  vkCreateBuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateBuffer".ptr, .vkCreateBuffer);
  vkCreateBufferView = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateBufferView".ptr, .vkCreateBufferView);
  vkCreateCommandPool = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateCommandPool".ptr, .vkCreateCommandPool);
  vkCreateComputePipelines = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateComputePipelines".ptr, .vkCreateComputePipelines);
  vkCreateDebugReportCallbackEXT = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateDebugReportCallbackEXT".ptr, .vkCreateDebugReportCallbackEXT);
  vkCreateDescriptorPool = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateDescriptorPool".ptr, .vkCreateDescriptorPool);
  vkCreateDescriptorSetLayout = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateDescriptorSetLayout".ptr, .vkCreateDescriptorSetLayout);
  vkCreateDevice = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateDevice".ptr, .vkCreateDevice);
  vkCreateDisplayModeKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateDisplayModeKHR".ptr, .vkCreateDisplayModeKHR);
  vkCreateDisplayPlaneSurfaceKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateDisplayPlaneSurfaceKHR".ptr, .vkCreateDisplayPlaneSurfaceKHR);
  vkCreateEvent = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateEvent".ptr, .vkCreateEvent);
  vkCreateFence = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateFence".ptr, .vkCreateFence);
  vkCreateFramebuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateFramebuffer".ptr, .vkCreateFramebuffer);
  vkCreateGraphicsPipelines = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateGraphicsPipelines".ptr, .vkCreateGraphicsPipelines);
  vkCreateImage = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateImage".ptr, .vkCreateImage);
  vkCreateImageView = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateImageView".ptr, .vkCreateImageView);
  vkCreatePipelineCache = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreatePipelineCache".ptr, .vkCreatePipelineCache);
  vkCreatePipelineLayout = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreatePipelineLayout".ptr, .vkCreatePipelineLayout);
  vkCreateQueryPool = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateQueryPool".ptr, .vkCreateQueryPool);
  vkCreateRenderPass = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateRenderPass".ptr, .vkCreateRenderPass);
  vkCreateSampler = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateSampler".ptr, .vkCreateSampler);
  vkCreateSemaphore = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateSemaphore".ptr, .vkCreateSemaphore);
  vkCreateShaderModule = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateShaderModule".ptr, .vkCreateShaderModule);
  vkCreateSharedSwapchainsKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateSharedSwapchainsKHR".ptr, .vkCreateSharedSwapchainsKHR);
  vkCreateSwapchainKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateSwapchainKHR".ptr, .vkCreateSwapchainKHR);
  vkDebugReportMessageEXT = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDebugReportMessageEXT".ptr, .vkDebugReportMessageEXT);
  vkDestroyBuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyBuffer".ptr, .vkDestroyBuffer);
  vkDestroyBufferView = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyBufferView".ptr, .vkDestroyBufferView);
  vkDestroyCommandPool = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyCommandPool".ptr, .vkDestroyCommandPool);
  vkDestroyDebugReportCallbackEXT = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyDebugReportCallbackEXT".ptr, .vkDestroyDebugReportCallbackEXT);
  vkDestroyDescriptorPool = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyDescriptorPool".ptr, .vkDestroyDescriptorPool);
  vkDestroyDescriptorSetLayout = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyDescriptorSetLayout".ptr, .vkDestroyDescriptorSetLayout);
  vkDestroyDevice = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyDevice".ptr, .vkDestroyDevice);
  vkDestroyEvent = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyEvent".ptr, .vkDestroyEvent);
  vkDestroyFence = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyFence".ptr, .vkDestroyFence);
  vkDestroyFramebuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyFramebuffer".ptr, .vkDestroyFramebuffer);
  vkDestroyImage = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyImage".ptr, .vkDestroyImage);
  vkDestroyImageView = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyImageView".ptr, .vkDestroyImageView);
  vkDestroyInstance = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyInstance".ptr, .vkDestroyInstance);
  vkDestroyPipeline = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyPipeline".ptr, .vkDestroyPipeline);
  vkDestroyPipelineCache = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyPipelineCache".ptr, .vkDestroyPipelineCache);
  vkDestroyPipelineLayout = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyPipelineLayout".ptr, .vkDestroyPipelineLayout);
  vkDestroyQueryPool = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyQueryPool".ptr, .vkDestroyQueryPool);
  vkDestroyRenderPass = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyRenderPass".ptr, .vkDestroyRenderPass);
  vkDestroySampler = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroySampler".ptr, .vkDestroySampler);
  vkDestroySemaphore = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroySemaphore".ptr, .vkDestroySemaphore);
  vkDestroyShaderModule = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroyShaderModule".ptr, .vkDestroyShaderModule);
  vkDestroySurfaceKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroySurfaceKHR".ptr, .vkDestroySurfaceKHR);
  vkDestroySwapchainKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDestroySwapchainKHR".ptr, .vkDestroySwapchainKHR);
  vkDeviceWaitIdle = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkDeviceWaitIdle".ptr, .vkDeviceWaitIdle);
  vkEndCommandBuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkEndCommandBuffer".ptr, .vkEndCommandBuffer);
  vkEnumerateDeviceExtensionProperties = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkEnumerateDeviceExtensionProperties".ptr, .vkEnumerateDeviceExtensionProperties);
  vkEnumerateDeviceLayerProperties = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkEnumerateDeviceLayerProperties".ptr, .vkEnumerateDeviceLayerProperties);
  vkEnumeratePhysicalDevices = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkEnumeratePhysicalDevices".ptr, .vkEnumeratePhysicalDevices);
  vkFlushMappedMemoryRanges = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkFlushMappedMemoryRanges".ptr, .vkFlushMappedMemoryRanges);
  vkFreeCommandBuffers = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkFreeCommandBuffers".ptr, .vkFreeCommandBuffers);
  vkFreeDescriptorSets = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkFreeDescriptorSets".ptr, .vkFreeDescriptorSets);
  vkFreeMemory = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkFreeMemory".ptr, .vkFreeMemory);
  vkGetBufferMemoryRequirements = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetBufferMemoryRequirements".ptr, .vkGetBufferMemoryRequirements);
  vkGetDeviceMemoryCommitment = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetDeviceMemoryCommitment".ptr, .vkGetDeviceMemoryCommitment);
  vkGetDeviceQueue = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetDeviceQueue".ptr, .vkGetDeviceQueue);
  vkGetDisplayModePropertiesKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetDisplayModePropertiesKHR".ptr, .vkGetDisplayModePropertiesKHR);
  vkGetDisplayPlaneCapabilitiesKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetDisplayPlaneCapabilitiesKHR".ptr, .vkGetDisplayPlaneCapabilitiesKHR);
  vkGetDisplayPlaneSupportedDisplaysKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetDisplayPlaneSupportedDisplaysKHR".ptr, .vkGetDisplayPlaneSupportedDisplaysKHR);
  vkGetEventStatus = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetEventStatus".ptr, .vkGetEventStatus);
  vkGetFenceStatus = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetFenceStatus".ptr, .vkGetFenceStatus);
  vkGetImageMemoryRequirements = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetImageMemoryRequirements".ptr, .vkGetImageMemoryRequirements);
  vkGetImageSparseMemoryRequirements = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetImageSparseMemoryRequirements".ptr, .vkGetImageSparseMemoryRequirements);
  vkGetImageSubresourceLayout = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetImageSubresourceLayout".ptr, .vkGetImageSubresourceLayout);
  vkGetInstanceProcAddr = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetInstanceProcAddr".ptr, .vkGetInstanceProcAddr);
  vkGetPhysicalDeviceDisplayPlanePropertiesKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceDisplayPlanePropertiesKHR".ptr, .vkGetPhysicalDeviceDisplayPlanePropertiesKHR);
  vkGetPhysicalDeviceDisplayPropertiesKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceDisplayPropertiesKHR".ptr, .vkGetPhysicalDeviceDisplayPropertiesKHR);
  vkGetPhysicalDeviceFeatures = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceFeatures".ptr, .vkGetPhysicalDeviceFeatures);
  vkGetPhysicalDeviceFormatProperties = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceFormatProperties".ptr, .vkGetPhysicalDeviceFormatProperties);
  vkGetPhysicalDeviceImageFormatProperties = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceImageFormatProperties".ptr, .vkGetPhysicalDeviceImageFormatProperties);
  vkGetPhysicalDeviceMemoryProperties = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceMemoryProperties".ptr, .vkGetPhysicalDeviceMemoryProperties);
  vkGetPhysicalDeviceProperties = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceProperties".ptr, .vkGetPhysicalDeviceProperties);
  vkGetPhysicalDeviceQueueFamilyProperties = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceQueueFamilyProperties".ptr, .vkGetPhysicalDeviceQueueFamilyProperties);
  vkGetPhysicalDeviceSparseImageFormatProperties = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceSparseImageFormatProperties".ptr, .vkGetPhysicalDeviceSparseImageFormatProperties);
  vkGetPhysicalDeviceSurfaceCapabilitiesKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR".ptr, .vkGetPhysicalDeviceSurfaceCapabilitiesKHR);
  vkGetPhysicalDeviceSurfaceFormatsKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceSurfaceFormatsKHR".ptr, .vkGetPhysicalDeviceSurfaceFormatsKHR);
  vkGetPhysicalDeviceSurfacePresentModesKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceSurfacePresentModesKHR".ptr, .vkGetPhysicalDeviceSurfacePresentModesKHR);
  vkGetPhysicalDeviceSurfaceSupportKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceSurfaceSupportKHR".ptr, .vkGetPhysicalDeviceSurfaceSupportKHR);
  vkGetPipelineCacheData = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPipelineCacheData".ptr, .vkGetPipelineCacheData);
  vkGetQueryPoolResults = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetQueryPoolResults".ptr, .vkGetQueryPoolResults);
  vkGetRenderAreaGranularity = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetRenderAreaGranularity".ptr, .vkGetRenderAreaGranularity);
  vkGetSwapchainImagesKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetSwapchainImagesKHR".ptr, .vkGetSwapchainImagesKHR);
  vkInvalidateMappedMemoryRanges = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkInvalidateMappedMemoryRanges".ptr, .vkInvalidateMappedMemoryRanges);
  vkMapMemory = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkMapMemory".ptr, .vkMapMemory);
  vkMergePipelineCaches = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkMergePipelineCaches".ptr, .vkMergePipelineCaches);
  vkQueueBindSparse = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkQueueBindSparse".ptr, .vkQueueBindSparse);
  vkQueuePresentKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkQueuePresentKHR".ptr, .vkQueuePresentKHR);
  vkQueueSubmit = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkQueueSubmit".ptr, .vkQueueSubmit);
  vkQueueWaitIdle = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkQueueWaitIdle".ptr, .vkQueueWaitIdle);
  vkResetCommandBuffer = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkResetCommandBuffer".ptr, .vkResetCommandBuffer);
  vkResetCommandPool = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkResetCommandPool".ptr, .vkResetCommandPool);
  vkResetDescriptorPool = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkResetDescriptorPool".ptr, .vkResetDescriptorPool);
  vkResetEvent = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkResetEvent".ptr, .vkResetEvent);
  vkResetFences = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkResetFences".ptr, .vkResetFences);
  vkSetEvent = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkSetEvent".ptr, .vkSetEvent);
  vkUnmapMemory = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkUnmapMemory".ptr, .vkUnmapMemory);
  vkUpdateDescriptorSets = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkUpdateDescriptorSets".ptr, .vkUpdateDescriptorSets);
  vkWaitForFences = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkWaitForFences".ptr, .vkWaitForFences);

  version(Windows)
  {
    vkCreateWin32SurfaceKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkCreateWin32SurfaceKHR".ptr, .vkCreateWin32SurfaceKHR);
    vkGetPhysicalDeviceWin32PresentationSupportKHR = LoadInstanceFunction(GetInstanceProcAddr, Instance, "vkGetPhysicalDeviceWin32PresentationSupportKHR".ptr, .vkGetPhysicalDeviceWin32PresentationSupportKHR);
  }
}

// Uses the current global functions as fallback.
void LoadAllDeviceFunctions(typeof(vkGetDeviceProcAddr) GetDeviceProcAddr,
                            VkDevice Device)
{
  assert(GetDeviceProcAddr);
  assert(Device);

  vkAcquireNextImageKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkAcquireNextImageKHR".ptr, .vkAcquireNextImageKHR);
  vkAllocateCommandBuffers = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkAllocateCommandBuffers".ptr, .vkAllocateCommandBuffers);
  vkAllocateDescriptorSets = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkAllocateDescriptorSets".ptr, .vkAllocateDescriptorSets);
  vkAllocateMemory = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkAllocateMemory".ptr, .vkAllocateMemory);
  vkBeginCommandBuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkBeginCommandBuffer".ptr, .vkBeginCommandBuffer);
  vkBindBufferMemory = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkBindBufferMemory".ptr, .vkBindBufferMemory);
  vkBindImageMemory = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkBindImageMemory".ptr, .vkBindImageMemory);
  vkCmdBeginQuery = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdBeginQuery".ptr, .vkCmdBeginQuery);
  vkCmdBeginRenderPass = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdBeginRenderPass".ptr, .vkCmdBeginRenderPass);
  vkCmdBindDescriptorSets = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdBindDescriptorSets".ptr, .vkCmdBindDescriptorSets);
  vkCmdBindIndexBuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdBindIndexBuffer".ptr, .vkCmdBindIndexBuffer);
  vkCmdBindPipeline = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdBindPipeline".ptr, .vkCmdBindPipeline);
  vkCmdBindVertexBuffers = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdBindVertexBuffers".ptr, .vkCmdBindVertexBuffers);
  vkCmdBlitImage = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdBlitImage".ptr, .vkCmdBlitImage);
  vkCmdClearAttachments = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdClearAttachments".ptr, .vkCmdClearAttachments);
  vkCmdClearColorImage = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdClearColorImage".ptr, .vkCmdClearColorImage);
  vkCmdClearDepthStencilImage = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdClearDepthStencilImage".ptr, .vkCmdClearDepthStencilImage);
  vkCmdCopyBuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdCopyBuffer".ptr, .vkCmdCopyBuffer);
  vkCmdCopyBufferToImage = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdCopyBufferToImage".ptr, .vkCmdCopyBufferToImage);
  vkCmdCopyImage = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdCopyImage".ptr, .vkCmdCopyImage);
  vkCmdCopyImageToBuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdCopyImageToBuffer".ptr, .vkCmdCopyImageToBuffer);
  vkCmdCopyQueryPoolResults = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdCopyQueryPoolResults".ptr, .vkCmdCopyQueryPoolResults);
  vkCmdDispatch = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdDispatch".ptr, .vkCmdDispatch);
  vkCmdDispatchIndirect = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdDispatchIndirect".ptr, .vkCmdDispatchIndirect);
  vkCmdDraw = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdDraw".ptr, .vkCmdDraw);
  vkCmdDrawIndexed = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdDrawIndexed".ptr, .vkCmdDrawIndexed);
  vkCmdDrawIndexedIndirect = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdDrawIndexedIndirect".ptr, .vkCmdDrawIndexedIndirect);
  vkCmdDrawIndirect = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdDrawIndirect".ptr, .vkCmdDrawIndirect);
  vkCmdEndQuery = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdEndQuery".ptr, .vkCmdEndQuery);
  vkCmdEndRenderPass = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdEndRenderPass".ptr, .vkCmdEndRenderPass);
  vkCmdExecuteCommands = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdExecuteCommands".ptr, .vkCmdExecuteCommands);
  vkCmdFillBuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdFillBuffer".ptr, .vkCmdFillBuffer);
  vkCmdNextSubpass = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdNextSubpass".ptr, .vkCmdNextSubpass);
  vkCmdPipelineBarrier = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdPipelineBarrier".ptr, .vkCmdPipelineBarrier);
  vkCmdPushConstants = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdPushConstants".ptr, .vkCmdPushConstants);
  vkCmdResetEvent = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdResetEvent".ptr, .vkCmdResetEvent);
  vkCmdResetQueryPool = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdResetQueryPool".ptr, .vkCmdResetQueryPool);
  vkCmdResolveImage = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdResolveImage".ptr, .vkCmdResolveImage);
  vkCmdSetBlendConstants = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdSetBlendConstants".ptr, .vkCmdSetBlendConstants);
  vkCmdSetDepthBias = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdSetDepthBias".ptr, .vkCmdSetDepthBias);
  vkCmdSetDepthBounds = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdSetDepthBounds".ptr, .vkCmdSetDepthBounds);
  vkCmdSetEvent = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdSetEvent".ptr, .vkCmdSetEvent);
  vkCmdSetLineWidth = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdSetLineWidth".ptr, .vkCmdSetLineWidth);
  vkCmdSetScissor = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdSetScissor".ptr, .vkCmdSetScissor);
  vkCmdSetStencilCompareMask = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdSetStencilCompareMask".ptr, .vkCmdSetStencilCompareMask);
  vkCmdSetStencilReference = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdSetStencilReference".ptr, .vkCmdSetStencilReference);
  vkCmdSetStencilWriteMask = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdSetStencilWriteMask".ptr, .vkCmdSetStencilWriteMask);
  vkCmdSetViewport = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdSetViewport".ptr, .vkCmdSetViewport);
  vkCmdUpdateBuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdUpdateBuffer".ptr, .vkCmdUpdateBuffer);
  vkCmdWaitEvents = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdWaitEvents".ptr, .vkCmdWaitEvents);
  vkCmdWriteTimestamp = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCmdWriteTimestamp".ptr, .vkCmdWriteTimestamp);
  vkCreateBuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateBuffer".ptr, .vkCreateBuffer);
  vkCreateBufferView = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateBufferView".ptr, .vkCreateBufferView);
  vkCreateCommandPool = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateCommandPool".ptr, .vkCreateCommandPool);
  vkCreateComputePipelines = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateComputePipelines".ptr, .vkCreateComputePipelines);
  vkCreateDebugReportCallbackEXT = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateDebugReportCallbackEXT".ptr, .vkCreateDebugReportCallbackEXT);
  vkCreateDescriptorPool = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateDescriptorPool".ptr, .vkCreateDescriptorPool);
  vkCreateDescriptorSetLayout = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateDescriptorSetLayout".ptr, .vkCreateDescriptorSetLayout);
  vkCreateDevice = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateDevice".ptr, .vkCreateDevice);
  vkCreateDisplayModeKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateDisplayModeKHR".ptr, .vkCreateDisplayModeKHR);
  vkCreateDisplayPlaneSurfaceKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateDisplayPlaneSurfaceKHR".ptr, .vkCreateDisplayPlaneSurfaceKHR);
  vkCreateEvent = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateEvent".ptr, .vkCreateEvent);
  vkCreateFence = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateFence".ptr, .vkCreateFence);
  vkCreateFramebuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateFramebuffer".ptr, .vkCreateFramebuffer);
  vkCreateGraphicsPipelines = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateGraphicsPipelines".ptr, .vkCreateGraphicsPipelines);
  vkCreateImage = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateImage".ptr, .vkCreateImage);
  vkCreateImageView = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateImageView".ptr, .vkCreateImageView);
  vkCreatePipelineCache = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreatePipelineCache".ptr, .vkCreatePipelineCache);
  vkCreatePipelineLayout = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreatePipelineLayout".ptr, .vkCreatePipelineLayout);
  vkCreateQueryPool = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateQueryPool".ptr, .vkCreateQueryPool);
  vkCreateRenderPass = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateRenderPass".ptr, .vkCreateRenderPass);
  vkCreateSampler = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateSampler".ptr, .vkCreateSampler);
  vkCreateSemaphore = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateSemaphore".ptr, .vkCreateSemaphore);
  vkCreateShaderModule = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateShaderModule".ptr, .vkCreateShaderModule);
  vkCreateSharedSwapchainsKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateSharedSwapchainsKHR".ptr, .vkCreateSharedSwapchainsKHR);
  vkCreateSwapchainKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkCreateSwapchainKHR".ptr, .vkCreateSwapchainKHR);
  vkDebugReportMessageEXT = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDebugReportMessageEXT".ptr, .vkDebugReportMessageEXT);
  vkDestroyBuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyBuffer".ptr, .vkDestroyBuffer);
  vkDestroyBufferView = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyBufferView".ptr, .vkDestroyBufferView);
  vkDestroyCommandPool = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyCommandPool".ptr, .vkDestroyCommandPool);
  vkDestroyDebugReportCallbackEXT = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyDebugReportCallbackEXT".ptr, .vkDestroyDebugReportCallbackEXT);
  vkDestroyDescriptorPool = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyDescriptorPool".ptr, .vkDestroyDescriptorPool);
  vkDestroyDescriptorSetLayout = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyDescriptorSetLayout".ptr, .vkDestroyDescriptorSetLayout);
  vkDestroyDevice = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyDevice".ptr, .vkDestroyDevice);
  vkDestroyEvent = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyEvent".ptr, .vkDestroyEvent);
  vkDestroyFence = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyFence".ptr, .vkDestroyFence);
  vkDestroyFramebuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyFramebuffer".ptr, .vkDestroyFramebuffer);
  vkDestroyImage = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyImage".ptr, .vkDestroyImage);
  vkDestroyImageView = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyImageView".ptr, .vkDestroyImageView);
  vkDestroyInstance = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyInstance".ptr, .vkDestroyInstance);
  vkDestroyPipeline = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyPipeline".ptr, .vkDestroyPipeline);
  vkDestroyPipelineCache = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyPipelineCache".ptr, .vkDestroyPipelineCache);
  vkDestroyPipelineLayout = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyPipelineLayout".ptr, .vkDestroyPipelineLayout);
  vkDestroyQueryPool = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyQueryPool".ptr, .vkDestroyQueryPool);
  vkDestroyRenderPass = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyRenderPass".ptr, .vkDestroyRenderPass);
  vkDestroySampler = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroySampler".ptr, .vkDestroySampler);
  vkDestroySemaphore = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroySemaphore".ptr, .vkDestroySemaphore);
  vkDestroyShaderModule = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroyShaderModule".ptr, .vkDestroyShaderModule);
  vkDestroySurfaceKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroySurfaceKHR".ptr, .vkDestroySurfaceKHR);
  vkDestroySwapchainKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDestroySwapchainKHR".ptr, .vkDestroySwapchainKHR);
  vkDeviceWaitIdle = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkDeviceWaitIdle".ptr, .vkDeviceWaitIdle);
  vkEndCommandBuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkEndCommandBuffer".ptr, .vkEndCommandBuffer);
  vkEnumerateDeviceExtensionProperties = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkEnumerateDeviceExtensionProperties".ptr, .vkEnumerateDeviceExtensionProperties);
  vkEnumerateDeviceLayerProperties = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkEnumerateDeviceLayerProperties".ptr, .vkEnumerateDeviceLayerProperties);
  vkEnumeratePhysicalDevices = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkEnumeratePhysicalDevices".ptr, .vkEnumeratePhysicalDevices);
  vkFlushMappedMemoryRanges = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkFlushMappedMemoryRanges".ptr, .vkFlushMappedMemoryRanges);
  vkFreeCommandBuffers = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkFreeCommandBuffers".ptr, .vkFreeCommandBuffers);
  vkFreeDescriptorSets = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkFreeDescriptorSets".ptr, .vkFreeDescriptorSets);
  vkFreeMemory = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkFreeMemory".ptr, .vkFreeMemory);
  vkGetBufferMemoryRequirements = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetBufferMemoryRequirements".ptr, .vkGetBufferMemoryRequirements);
  vkGetDeviceMemoryCommitment = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetDeviceMemoryCommitment".ptr, .vkGetDeviceMemoryCommitment);
  vkGetDeviceQueue = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetDeviceQueue".ptr, .vkGetDeviceQueue);
  vkGetDisplayModePropertiesKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetDisplayModePropertiesKHR".ptr, .vkGetDisplayModePropertiesKHR);
  vkGetDisplayPlaneCapabilitiesKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetDisplayPlaneCapabilitiesKHR".ptr, .vkGetDisplayPlaneCapabilitiesKHR);
  vkGetDisplayPlaneSupportedDisplaysKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetDisplayPlaneSupportedDisplaysKHR".ptr, .vkGetDisplayPlaneSupportedDisplaysKHR);
  vkGetEventStatus = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetEventStatus".ptr, .vkGetEventStatus);
  vkGetFenceStatus = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetFenceStatus".ptr, .vkGetFenceStatus);
  vkGetImageMemoryRequirements = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetImageMemoryRequirements".ptr, .vkGetImageMemoryRequirements);
  vkGetImageSparseMemoryRequirements = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetImageSparseMemoryRequirements".ptr, .vkGetImageSparseMemoryRequirements);
  vkGetImageSubresourceLayout = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetImageSubresourceLayout".ptr, .vkGetImageSubresourceLayout);
  vkGetInstanceProcAddr = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetInstanceProcAddr".ptr, .vkGetInstanceProcAddr);
  vkGetPhysicalDeviceDisplayPlanePropertiesKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceDisplayPlanePropertiesKHR".ptr, .vkGetPhysicalDeviceDisplayPlanePropertiesKHR);
  vkGetPhysicalDeviceDisplayPropertiesKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceDisplayPropertiesKHR".ptr, .vkGetPhysicalDeviceDisplayPropertiesKHR);
  vkGetPhysicalDeviceFeatures = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceFeatures".ptr, .vkGetPhysicalDeviceFeatures);
  vkGetPhysicalDeviceFormatProperties = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceFormatProperties".ptr, .vkGetPhysicalDeviceFormatProperties);
  vkGetPhysicalDeviceImageFormatProperties = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceImageFormatProperties".ptr, .vkGetPhysicalDeviceImageFormatProperties);
  vkGetPhysicalDeviceMemoryProperties = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceMemoryProperties".ptr, .vkGetPhysicalDeviceMemoryProperties);
  vkGetPhysicalDeviceProperties = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceProperties".ptr, .vkGetPhysicalDeviceProperties);
  vkGetPhysicalDeviceQueueFamilyProperties = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceQueueFamilyProperties".ptr, .vkGetPhysicalDeviceQueueFamilyProperties);
  vkGetPhysicalDeviceSparseImageFormatProperties = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceSparseImageFormatProperties".ptr, .vkGetPhysicalDeviceSparseImageFormatProperties);
  vkGetPhysicalDeviceSurfaceCapabilitiesKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR".ptr, .vkGetPhysicalDeviceSurfaceCapabilitiesKHR);
  vkGetPhysicalDeviceSurfaceFormatsKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceSurfaceFormatsKHR".ptr, .vkGetPhysicalDeviceSurfaceFormatsKHR);
  vkGetPhysicalDeviceSurfacePresentModesKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceSurfacePresentModesKHR".ptr, .vkGetPhysicalDeviceSurfacePresentModesKHR);
  vkGetPhysicalDeviceSurfaceSupportKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPhysicalDeviceSurfaceSupportKHR".ptr, .vkGetPhysicalDeviceSurfaceSupportKHR);
  vkGetPipelineCacheData = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetPipelineCacheData".ptr, .vkGetPipelineCacheData);
  vkGetQueryPoolResults = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetQueryPoolResults".ptr, .vkGetQueryPoolResults);
  vkGetRenderAreaGranularity = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetRenderAreaGranularity".ptr, .vkGetRenderAreaGranularity);
  vkGetSwapchainImagesKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkGetSwapchainImagesKHR".ptr, .vkGetSwapchainImagesKHR);
  vkInvalidateMappedMemoryRanges = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkInvalidateMappedMemoryRanges".ptr, .vkInvalidateMappedMemoryRanges);
  vkMapMemory = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkMapMemory".ptr, .vkMapMemory);
  vkMergePipelineCaches = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkMergePipelineCaches".ptr, .vkMergePipelineCaches);
  vkQueueBindSparse = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkQueueBindSparse".ptr, .vkQueueBindSparse);
  vkQueuePresentKHR = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkQueuePresentKHR".ptr, .vkQueuePresentKHR);
  vkQueueSubmit = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkQueueSubmit".ptr, .vkQueueSubmit);
  vkQueueWaitIdle = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkQueueWaitIdle".ptr, .vkQueueWaitIdle);
  vkResetCommandBuffer = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkResetCommandBuffer".ptr, .vkResetCommandBuffer);
  vkResetCommandPool = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkResetCommandPool".ptr, .vkResetCommandPool);
  vkResetDescriptorPool = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkResetDescriptorPool".ptr, .vkResetDescriptorPool);
  vkResetEvent = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkResetEvent".ptr, .vkResetEvent);
  vkResetFences = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkResetFences".ptr, .vkResetFences);
  vkSetEvent = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkSetEvent".ptr, .vkSetEvent);
  vkUnmapMemory = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkUnmapMemory".ptr, .vkUnmapMemory);
  vkUpdateDescriptorSets = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkUpdateDescriptorSets".ptr, .vkUpdateDescriptorSets);
  vkWaitForFences = LoadDeviceFunction(GetDeviceProcAddr, Device, "vkWaitForFences".ptr, .vkWaitForFences);
}

VkFormat ImageFormatToVulkan(ImageFormat KrepelFormat)
{
  // TODO(Manu): final switch.
  switch(KrepelFormat)
  {
    default: return VK_FORMAT_UNDEFINED;

    //
    // BGR formats
    //
    case ImageFormat.B8G8R8_UNorm:        return VK_FORMAT_B8G8R8_UNORM;

    //
    // RGBA formats
    //
    case ImageFormat.R8G8B8A8_UNorm:      return VK_FORMAT_R8G8B8A8_UNORM;
    case ImageFormat.R8G8B8A8_SNorm:      return VK_FORMAT_R8G8B8A8_SNORM;
    case ImageFormat.R8G8B8A8_UNorm_sRGB: return VK_FORMAT_R8G8B8A8_SRGB;
    //case ImageFormat.R8G8B8A8_Typeless:   return VK_FORMAT_R8G8B8A8_SSCALED;
    case ImageFormat.R8G8B8A8_UInt:       return VK_FORMAT_R8G8B8A8_UINT;
    case ImageFormat.R8G8B8A8_SInt:       return VK_FORMAT_R8G8B8A8_SINT;

    //
    // BGRA formats
    //
    case ImageFormat.B8G8R8A8_UNorm:      return VK_FORMAT_B8G8R8A8_UNORM;
    //case ImageFormat.B8G8R8A8_Typeless:   return VK_FORMAT_B8G8R8A8_SSCALED;
    case ImageFormat.B8G8R8A8_UNorm_sRGB: return VK_FORMAT_B8G8R8A8_SRGB;

    //
    // Block compressed formats
    //
    case ImageFormat.BC1_UNorm:           return VK_FORMAT_BC1_RGBA_UNORM_BLOCK;
    case ImageFormat.BC1_UNorm_sRGB:      return VK_FORMAT_BC1_RGBA_SRGB_BLOCK;

    case ImageFormat.BC2_UNorm:           return VK_FORMAT_BC2_UNORM_BLOCK;
    case ImageFormat.BC2_UNorm_sRGB:      return VK_FORMAT_BC2_SRGB_BLOCK;

    case ImageFormat.BC3_UNorm:           return VK_FORMAT_BC3_UNORM_BLOCK;
    case ImageFormat.BC3_UNorm_sRGB:      return VK_FORMAT_BC3_SRGB_BLOCK;

    case ImageFormat.BC4_UNorm:           return VK_FORMAT_BC4_UNORM_BLOCK;
    case ImageFormat.BC4_SNorm:           return VK_FORMAT_BC4_SNORM_BLOCK;

    case ImageFormat.BC5_UNorm:           return VK_FORMAT_BC5_UNORM_BLOCK;
    case ImageFormat.BC5_SNorm:           return VK_FORMAT_BC5_SNORM_BLOCK;

    case ImageFormat.BC6H_UF16:           return VK_FORMAT_BC6H_UFLOAT_BLOCK;
    case ImageFormat.BC6H_SF16:           return VK_FORMAT_BC6H_SFLOAT_BLOCK;

    case ImageFormat.BC7_UNorm:           return VK_FORMAT_BC7_UNORM_BLOCK;
    case ImageFormat.BC7_UNorm_sRGB:      return VK_FORMAT_BC7_SRGB_BLOCK;
  }
}

ImageFormat ImageFormatFromVulkan(VkFormat VulkanFormat)
{
  // TODO(Manu): Complete this. Check out whether the ones that are commented
  // out are correct.
  switch(VulkanFormat)
  {
    default: return ImageFormat.Unknown;

    //
    // BGR formats
    //
    case VK_FORMAT_B8G8R8_UNORM: return ImageFormat.B8G8R8_UNorm;

    //
    // RGBA formats
    //
    case VK_FORMAT_R8G8B8A8_UNORM:   return ImageFormat.R8G8B8A8_UNorm;
    case VK_FORMAT_R8G8B8A8_SNORM:   return ImageFormat.R8G8B8A8_SNorm;
    case VK_FORMAT_R8G8B8A8_SRGB:    return ImageFormat.R8G8B8A8_UNorm_sRGB;
    //case VK_FORMAT_R8G8B8A8_SSCALED: return ImageFormat.R8G8B8A8_Typeless;
    case VK_FORMAT_R8G8B8A8_UINT:    return ImageFormat.R8G8B8A8_UInt;
    case VK_FORMAT_R8G8B8A8_SINT:    return ImageFormat.R8G8B8A8_SInt;

    //
    // BGRA formats
    //
    case VK_FORMAT_B8G8R8A8_UNORM:      return ImageFormat.B8G8R8A8_UNorm;
    //case VK_FORMAT_B8G8R8A8_SSCALED:    return ImageFormat.B8G8R8A8_Typeless;
    case VK_FORMAT_B8G8R8A8_SRGB: return ImageFormat.B8G8R8A8_UNorm_sRGB;

    //
    // Block compressed formats
    //
    case VK_FORMAT_BC1_RGBA_UNORM_BLOCK: return ImageFormat.BC1_UNorm;
    case VK_FORMAT_BC1_RGBA_SRGB_BLOCK:  return ImageFormat.BC1_UNorm_sRGB;

    case VK_FORMAT_BC2_UNORM_BLOCK:      return ImageFormat.BC2_UNorm;
    case VK_FORMAT_BC2_SRGB_BLOCK:       return ImageFormat.BC2_UNorm_sRGB;

    case VK_FORMAT_BC3_UNORM_BLOCK:      return ImageFormat.BC3_UNorm;
    case VK_FORMAT_BC3_SRGB_BLOCK:       return ImageFormat.BC3_UNorm_sRGB;

    case VK_FORMAT_BC4_UNORM_BLOCK:      return ImageFormat.BC4_UNorm;
    case VK_FORMAT_BC4_SNORM_BLOCK:      return ImageFormat.BC4_SNorm;

    case VK_FORMAT_BC5_UNORM_BLOCK:      return ImageFormat.BC5_UNorm;
    case VK_FORMAT_BC5_SNORM_BLOCK:      return ImageFormat.BC5_SNorm;

    case VK_FORMAT_BC6H_UFLOAT_BLOCK:    return ImageFormat.BC6H_UF16;
    case VK_FORMAT_BC6H_SFLOAT_BLOCK:    return ImageFormat.BC6H_SF16;

    case VK_FORMAT_BC7_UNORM_BLOCK:      return ImageFormat.BC7_UNorm;
    case VK_FORMAT_BC7_SRGB_BLOCK:       return ImageFormat.BC7_UNorm_sRGB;
  }
}
