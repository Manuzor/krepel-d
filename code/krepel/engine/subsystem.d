module krepel.engine.subsystem;

import krepel;
import krepel.game_framework.tick;

class Subsystem
{
  IAllocator Allocator;
  float TimeDilation = 1.0f;
  float FixedTickInterval = 0.0166666f;
  float PendingElapsedTime = 0.0f;
  bool FixedTimeStep = true;
  float TimeElapsedFromStart = 0.0f;

  void TickSubsystem(float ElapsedTime)
  {
    assert(ElapsedTime > 0.0f);
    if (FixedTimeStep)
    {
      assert(FixedTickInterval > 0.0f, "Cannot have 0 or negative update interval");
      PendingElapsedTime += ElapsedTime;
      while(PendingElapsedTime >= FixedTickInterval)
      {
        PendingElapsedTime -= FixedTickInterval;
        TimeElapsedFromStart += FixedTickInterval;
        TickData UpdateData = TickData(FixedTickInterval, TimeDilation, TimeElapsedFromStart);
        Tick(UpdateData);
      }
    }
    else
    {
      TimeElapsedFromStart += ElapsedTime;
      TickData UpdateData = TickData(ElapsedTime, TimeDilation, TimeElapsedFromStart);
      Tick(UpdateData);
    }
  }

  abstract void Tick(TickData Tick);
}
