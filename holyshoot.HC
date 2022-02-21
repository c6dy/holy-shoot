


$SP,"<1>",BI=1$


$SP,"<2>",BI=2$





$SP,"<3>",BI=3$



#define BULLET_RADIUS   3
#define ENEMY_SPEED     2
#define MAX_ENEMY_COUNT 5
#define ENEMY_FIRE_RATE 1
#define WIN_SCORE       100

class Collider
{
  I64 x, y, radius;
};

class Keys
{
  Bool up, down, left, right, space;
};

class Bullet
{
  Bullet *next, *last;
  I64 x, y;
  Bool active;
};

class Player
{
  I64 x, y, hp, score;
  Bullet bullets;
  Collider collider;
  Bool destroyed;
};

class Attack
{
  Attack *next, *last;
  F64 radius, time;
  I64 origin_x, origin_y;
  Bullet bullets[10];
};

class Enemy
{
  Enemy *next, *last;  
  I64 x, y, hp, destroyed_frame_count;
  Bool destroyed;
  F64 last_attack;
  Collider collider; 
};

Player player;
Keys keys;
Enemy enemies;
I64 enemy_count = 0;
Attack attacks;
I8 status;


U0 Fire()
{ 
  Bullet *bullet = MAlloc(sizeof(Bullet));
  bullet->x = player.x;
  bullet->y = player.y;
  QueIns(bullet, player.bullets.last); 
}

U0 EnemyFire(Enemy *enemy)
{
  Attack *attack = MAlloc(sizeof(Attack));
  
  I64 i;
  for(i = 0; i < 10; i++)
   attack->bullets[i].active = TRUE; 

  attack->origin_x = enemy->x - 30;
  attack->origin_y = enemy->y - 8;
  attack->radius = 25;
  enemy->last_attack = tS;
  attack->time = tS;
  QueIns(attack, attacks.last);
}

U0 HandleInput()
{
  if(keys.space)
    Fire;
  if(keys.up && player.y > 0)
    player.y -= 10;
  if(keys.down && player.y < 450)
    player.y += 10;
  if(keys.left && player.x > -20)
    player.x -= 10;
  if(keys.right && player.x < 600)
    player.x += 10;
}

U0 SpawnEnemy()
{
 if(enemy_count < MAX_ENEMY_COUNT)
 {
   Enemy *enemy = MAlloc(sizeof(Enemy));
   enemy->x = (RandI64 % 640) + 30;
   enemy->y = (RandI64 % 480) - 480;
   enemy->destroyed = FALSE;
   enemy->collider.x = enemy->x;
   enemy->collider.y = enemy->y;
   enemy->collider.radius = 15;
   enemy->hp = 20;
   enemy->destroyed_frame_count = 0;
   enemy->last_attack = tS;
   QueIns(enemy, enemies.last);
   enemy_count++;
 } 
}

U0 DestroyEnemy(Enemy *enemy)
{
  QueRem(enemy);
  Free(enemy);
  enemy_count--;
}

U0 DestroyBullet(Bullet *bullet)
{
  QueRem(bullet);
  Free(bullet);
}

U0 DestroyAttack(Attack *attack)
{
  QueRem(attack);
  Free(attack);
}

Bool EnemyOutOfBounds(Enemy *enemy)
{
  return (enemy->x > 640 || enemy->x < 0 || enemy->y > 500); 
}

U0 UpdateEnemyColliders()
{
  Enemy *tmp = enemies.next;
  while(tmp != &enemies)
  { 
    tmp->collider.x = tmp->x - 30;
    tmp->collider.y = tmp->y - 12;

    tmp = tmp->next;
  }
}

U0 UpdatePlayerCollider()
{
  player.collider.x = player.x + 30;
  player.collider.y = player.y + 12;
}

Bool CheckCollision(Collider *a, Collider *b)
{
  F64 distance = Sqrt((a->x - b->x) * (a->x - b->x) + 
                      (a->y - b->y) * (a->y - b->y)
                     );
  return (distance < (a->radius + b->radius));
}


U0 DetectCollisions()
{
  Enemy *enemy = enemies.next;

  while(enemy != &enemies)
  { 
    Bullet *bullet = player.bullets.next;
    while(bullet != &player.bullets)
    { 
      // Create a temporary collider for the bullet
      Collider collider;
      collider.x = bullet->x + 30;
      collider.y = bullet->y;
      collider.radius = 3;

      if(CheckCollision(&collider, &enemy->collider))
      {    
        DestroyBullet(bullet);
        if(enemy->hp > 1)
          enemy->hp--;
        else
        {
	  enemy->destroyed = TRUE;
          if(enemy->destroyed_frame_count == 0)
            player.score++;
          if(player.score == WIN_SCORE)
            status = 2;
          break;
        }
      }  
       
      bullet = bullet->next;
    }
 
    enemy = enemy->next;
  }


  // Detect collisions between enemy bullets and player
  Attack *attack = attacks.next;
  while(attack != &attacks)
  { 
    I64 i;
    for(i = 0; i < 10; i++)
    {
      Bullet *bul = &attack->bullets[i];
      if(bul->active)
      {
        Collider collider2;
        collider2.x = bul->x;
        collider2.y = bul->y;
        collider2.radius = 3;

        if(CheckCollision(&collider2, &player.collider))
        { 
          bul->active = FALSE;
          player.hp--;
	  break; 
        }
      }      
    }
    
    attack = attack->next;
  }
}

U0 DrawIt(CTask *tsk, CDC *dc)
{
  Bullet *tmp;
  Attack *tmp2;
  Enemy *tmp3;

  // Fill device context with black
  DCFill(dc, BLACK);
  
  // Draw the player
  if(player.hp > 0)
  {
    dc->color = LTGRAY;
    Sprite3B(dc, player.x, player.y, 0, $IB,"<3>",BI=3$);

    // Hearts
    dc->color = WHITE;
    I64 i;
    for(i = 0; i < player.hp; i++)
       Sprite3B(dc, (i * 30), 20, 0, $IB,"<2>",BI=2$);
  }
  else
  { 
    dc->color = RED;
    Sprite3B(dc, player.x + 8, player.y + 10, 0, $IB,"<4>",BI=4$);
    status = 1;
  }

  // Draw player bullets
  tmp = player.bullets.next;
  dc->color = YELLOW;
  while(tmp != &player.bullets)
  { 
    // Bullet has passed top of screen
    if(tmp->y < 0)
      DestroyBullet(tmp); 
    else
     GrCircle(dc, tmp->x + 30, tmp->y -= 10, BULLET_RADIUS);

    tmp = tmp->next;
  }

  // Draw enemies
  
  tmp3 = enemies.next;
  while(tmp3 != &enemies)
  { 
    if(tmp3->destroyed == TRUE || EnemyOutOfBounds(tmp3))
    { 
      dc->color = RED;
      Sprite3B(dc, tmp3->x - 55, tmp3->y, 0, $IB,"<1>",BI=1$);
      tmp3->destroyed_frame_count++;
      
      if(tmp3->destroyed_frame_count == 10)
        DestroyEnemy(tmp3);
    }
    else
    {
      dc->color = RED;
      Sprite3ZB(dc, tmp3->x, tmp3->y += ENEMY_SPEED, 0, $IB,"<3>",BI=3$, 3.14);
    }
    
    // Enemy attack
    if((tS - tmp3->last_attack) > ENEMY_FIRE_RATE)
      EnemyFire(tmp3);

    tmp3 = tmp3->next;
  }
    
   
  // Draw enemy bullets
  dc->color = RED;
  tmp2 = attacks.next;
  while(tmp2 != &attacks)
  { 
    // If attack has been active for more than 5 sec
    if(tS - tmp2->time > 5) 
      DestroyAttack(tmp2);
    else
    { 
      for(i = 1; i <= 10; i++)
      {
        Bullet *bullet = &tmp2->bullets[i-1];
        bullet->x = (tmp2->radius * Cos(36 * i)) + tmp2->origin_x;
        bullet->y = (tmp2->radius * Sin(36 * i)) + tmp2->origin_y;
        
        if(bullet->active)
          GrCircle(dc, bullet->x, bullet->y, BULLET_RADIUS);
      }
      
      tmp2->radius += 3;
    }
          
    tmp2 = tmp2->next;  
  }
  
  dc->color = WHITE;
  GrPrint(dc, 15, 50, "Score: %d", player.score);
   
  if(status == 0)
  {
    HandleInput;
    SpawnEnemy;
    UpdateEnemyColliders;
    UpdatePlayerCollider;
    DetectCollisions;
  }
  
  if(status == 1)
  {
    if(Blink)
    {
      dc->color = WHITE;
      GrPrint(dc, 275, 250, "GAME OVER");
    }   
  }

  if(status == 2)
  { 
    if(Blink)
    {
      dc->color = WHITE;
      GrPrint(dc, 275, 250, "YOU WIN!");
    }    
  }
}


U0 Init()
{
  player.x = (640/2) - 32;
  player.y = 440;
  player.hp = 5;
  player.collider.radius = 15;
  player.destroyed = FALSE;
  player.score = 0;

  keys.up    = FALSE;
  keys.down  = FALSE;
  keys.left  = FALSE;
  keys.right = FALSE;
  keys.space = FALSE;

  status = 0;

  QueInit(&player.bullets);
  QueInit(&attacks);
  QueInit(&enemies);
}


U0 Main()
{
  I64 arg1, arg2;

  SettingsPush;
  WinBorder;
  WinMax;
  DocCursor;
  DocClear;
   
  Fs->draw_it = &DrawIt;

  Init;

  try
  {
    while(TRUE)
    {
      // NOTE: arg1 == ch and arg2 == sc
      switch(GetMsg(&arg1, &arg2, 1<<MSG_KEY_DOWN+1<<MSG_KEY_UP))
      {
        case MSG_KEY_DOWN:
	  switch(arg1)
	  {
            case CH_SPACE: keys.space = TRUE; break;
            case CH_SHIFT_ESC: goto done;
	    case 0: 
	      switch(arg2.u8[0])
	      {
                case SC_CURSOR_UP: keys.up = TRUE; break;
	        case SC_CURSOR_DOWN: keys.down = TRUE; break;
		case SC_CURSOR_LEFT: keys.left = TRUE; break;
		case SC_CURSOR_RIGHT: keys.right = TRUE; break;
	      }
	    break;
	  }
	break;
	
	case MSG_KEY_UP:
	  switch(arg1)
	  {
            case CH_SPACE: keys.space = FALSE; break;
	    case 0: 
	      switch(arg2.u8[0])
	      {
                case SC_CURSOR_UP: keys.up = FALSE; break;
	        case SC_CURSOR_DOWN: keys.down = FALSE; break;
		case SC_CURSOR_LEFT: keys.left = FALSE; break;
		case SC_CURSOR_RIGHT: keys.right = FALSE; break;
	      }
	    break;

	  }
	break;
      }
    }
  done:
  }
  catch
  {
    PutExcept;
    SettingsPop;
    MenuPop;
  }
}

Main;        À         ûÿÿÿ      ñÿÿÿ      õÿÿÿ      ÿÿÿÿ      ðÿÿÿ   ÿÿÿÿ   ÿÿÿÿ   ÿÿÿÿ   íÿÿÿ   ìÿÿÿ   ìÿÿÿ   ìÿÿÿ   ûÿÿÿ   óÿÿÿ   öÿÿÿ   õÿÿÿ   õÿÿÿ   öÿÿÿ   õÿÿÿ        À         ûÿÿÿ      ñÿÿÿ      õÿÿÿ      ÿÿÿÿ      ðÿÿÿ   ÿÿÿÿ   ÿÿÿÿ   ÿÿÿÿ   íÿÿÿ   ìÿÿÿ   ìÿÿÿ   ìÿÿÿ   ûÿÿÿ   óÿÿÿ   öÿÿÿ   õÿÿÿ   õÿÿÿ   öÿÿÿ   õÿÿÿ        ‰                     þÿÿÿ           þÿÿÿ           üÿÿÿ&   þÿÿÿ   üÿÿÿ   þÿÿÿ&   þÿÿÿ(       (       *         þÿÿÿ                                         
      
                                                                 "      "   
   $      $      &   
   &      (            $         
      
         $   
                                    (                                              þÿÿÿ                      
   "                                   þÿÿÿ&       $      (      $      $      $      &              ¬        üÿÿÿ   þÿÿÿ   üÿÿÿ    þÿÿÿ   øÿÿÿ   úÿÿÿ   úÿÿÿ   üÿÿÿ   úÿÿÿ    üÿÿÿ    þÿÿÿ"         þÿÿÿ      "      $   
            
   $   
   &         
         &      *                              *      ,            ,                                                                                                                      