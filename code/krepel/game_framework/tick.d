module krepel.game_framework.tick;

struct TickData
{
  float RealtimeElapsedTime;
  float TimeDilation;
  float TimeFromStart;
  @property float ElapsedTime() const
  {
    return RealtimeElapsedTime * TimeDilation;
  }
  @property float UnscaledTime() const
  {
    return RealtimeElapsedTime;
  }
}
