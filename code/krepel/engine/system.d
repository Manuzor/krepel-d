module krepel.engine.system;

import krepel;
import krepel.game_framework;
import krepel.engine.engine;

interface ISystem
{
  void Initialize(Engine ParentEngine);
  void TickSystem(TickData Tick);
  void Destroy();
}
