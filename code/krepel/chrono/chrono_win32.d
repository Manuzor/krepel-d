module krepel.chrono.win32;

import krepel;
version(Windows):
import core.sys.windows.windows;

struct Timer
{
  long StartTime;
  long EndTime;
  long Frequency;

  void Start()
  {
    QueryPerformanceCounter(&StartTime);
    QueryPerformanceFrequency(&Frequency);
  }

  void Stop()
  {
    QueryPerformanceCounter(&EndTime);
  }

  double TotalElapsedSeconds()
  {
    return cast(double)(EndTime - StartTime) / cast(double)Frequency;
  }
}
