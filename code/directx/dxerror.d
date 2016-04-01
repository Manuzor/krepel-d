module directx.dxerror;

// These should be defined in core.sys.windows.winerror, but for some reason they are not.

enum DXGI_STATUS_OCCLUDED                                     = 0x087A0001;
enum DXGI_STATUS_CLIPPED                                      = 0x087A0002;
enum DXGI_STATUS_NO_REDIRECTION                               = 0x087A0004;
enum DXGI_STATUS_NO_DESKTOP_ACCESS                            = 0x087A0005;
enum DXGI_STATUS_GRAPHICS_VIDPN_SOURCE_IN_USE                 = 0x087A0006;
enum DXGI_STATUS_MODE_CHANGED                                 = 0x087A0007;
enum DXGI_STATUS_MODE_CHANGE_IN_PROGRESS                      = 0x087A0008;
enum DXGI_ERROR_INVALID_CALL                                  = 0x887A0001;
enum DXGI_ERROR_NOT_FOUND                                     = 0x887A0002;
enum DXGI_ERROR_MORE_DATA                                     = 0x887A0003;
enum DXGI_ERROR_UNSUPPORTED                                   = 0x887A0004;
enum DXGI_ERROR_DEVICE_REMOVED                                = 0x887A0005;
enum DXGI_ERROR_DEVICE_HUNG                                   = 0x887A0006;
enum DXGI_ERROR_DEVICE_RESET                                  = 0x887A0007;
enum DXGI_ERROR_WAS_STILL_DRAWING                             = 0x887A000A;
enum DXGI_ERROR_FRAME_STATISTICS_DISJOINT                     = 0x887A000B;
enum DXGI_ERROR_GRAPHICS_VIDPN_SOURCE_IN_USE                  = 0x887A000C;
enum DXGI_ERROR_DRIVER_INTERNAL_ERROR                         = 0x887A0020;
enum DXGI_ERROR_NONEXCLUSIVE                                  = 0x887A0021;
enum DXGI_ERROR_NOT_CURRENTLY_AVAILABLE                       = 0x887A0022;
enum DXGI_ERROR_REMOTE_CLIENT_DISCONNECTED                    = 0x887A0023;
enum DXGI_ERROR_REMOTE_OUTOFMEMORY                            = 0x887A0024;
enum DXGI_ERROR_ACCESS_LOST                                   = 0x887A0026;
enum DXGI_ERROR_WAIT_TIMEOUT                                  = 0x887A0027;
enum DXGI_ERROR_SESSION_DISCONNECTED                          = 0x887A0028;
enum DXGI_ERROR_RESTRICT_TO_OUTPUT_STALE                      = 0x887A0029;
enum DXGI_ERROR_CANNOT_PROTECT_CONTENT                        = 0x887A002A;
enum DXGI_ERROR_ACCESS_DENIED                                 = 0x887A002B;
enum DXGI_ERROR_NAME_ALREADY_EXISTS                           = 0x887A002C;
enum DXGI_ERROR_SDK_COMPONENT_MISSING                         = 0x887A002D;
enum DXGI_ERROR_NOT_CURRENT                                   = 0x887A002E;
enum DXGI_ERROR_HW_PROTECTION_OUTOFMEMORY                     = 0x887A0030;
enum DXGI_STATUS_UNOCCLUDED                                   = 0x087A0009;
enum DXGI_STATUS_DDA_WAS_STILL_DRAWING                        = 0x087A000A;
enum DXGI_ERROR_MODE_CHANGE_IN_PROGRESS                       = 0x887A0025;
enum DXGI_STATUS_PRESENT_REQUIRED                             = 0x087A002F;
enum DXGI_DDI_ERR_WASSTILLDRAWING                             = 0x887B0001;
enum DXGI_DDI_ERR_UNSUPPORTED                                 = 0x887B0002;
enum DXGI_DDI_ERR_NONEXCLUSIVE                                = 0x887B0003;
enum D3D11_ERROR_TOO_MANY_UNIQUE_STATE_OBJECTS                = 0x887C0001;
enum D3D11_ERROR_FILE_NOT_FOUND                               = 0x887C0002;
enum D3D11_ERROR_TOO_MANY_UNIQUE_VIEW_OBJECTS                 = 0x887C0003;
enum D3D11_ERROR_DEFERRED_CONTEXT_MAP_WITHOUT_INITIAL_DISCARD = 0x887C0004;
