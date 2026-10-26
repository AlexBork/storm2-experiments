// Orchard (Obstgarten) kid's game

mdp

// constants
const int NUM_FRUIT; //=10; // Number of fruits per fruit type
const int NUM_CHOOSE; //=2; // Number of choices when rolling 'bucket'
const int DISTANCE_RAVEN; //=9; // Distance of raven from orchard
const double probRaven = 1/6;
const double probBucket = 1/6;
const double probFruit = 1 - probRaven - probBucket;

module orchard

	tApple : [0..NUM_FRUIT] init NUM_FRUIT;
	tPear : [0..NUM_FRUIT] init NUM_FRUIT;
	tCherry : [0..NUM_FRUIT] init NUM_FRUIT;
	tPlum : [0..NUM_FRUIT] init NUM_FRUIT;
	raven : [0..DISTANCE_RAVEN] init DISTANCE_RAVEN;
	// Game states
	// s=0 : roll dice and perform action
	// s=1 : choose a fruit after rolling 'bucket'
	s : [0..1] init 0;
	// Number of choices for 'bucket' done so far
	c : [0..NUM_CHOOSE] init 0;

	[] (s=0) -> 1/4 * probFruit : (tApple' =tApple>0  ? tApple-1  : 0)
	         +  1/4 * probFruit : (tPear'  =tPear>0   ? tPear-1   : 0)
	         +  1/4 * probFruit : (tCherry'=tCherry>0 ? tCherry-1 : 0)
	         +  1/4 * probFruit : (tPlum'  =tPlum>0   ? tPlum-1   : 0)
	         +  probBucket      : (s'=1) & (c'=0)
	         +  probRaven       : (raven'=raven>0 ? raven-1 : 0)
		       ;
	// Choose fruit
	[chooseApple]  (s=1 & c < NUM_CHOOSE & tApple>0)  -> 1 : (tApple'=tApple-1)   & (c'=c+1);
	[choosePear]   (s=1 & c < NUM_CHOOSE & tPear>0)   -> 1 : (tPear'=tPear-1)     & (c'=c+1);
	[chooseCherry] (s=1 & c < NUM_CHOOSE & tCherry>0) -> 1 : (tCherry'=tCherry-1) & (c'=c+1);
	[choosePlum]   (s=1 & c < NUM_CHOOSE & tPlum>0)   -> 1 : (tPlum'=tPlum-1)     & (c'=c+1);
	[]             (s=1 & c < NUM_CHOOSE & all_trees_empty) -> 1 : (s'=0) & (c'=0); // No fruit can be picked
	[] (s=1 & c = NUM_CHOOSE) -> 1 : (s'=0) & (c'=0);

endmodule

// labels
formula all_trees_empty = tApple = 0
                        & tPear = 0
			& tCherry = 0
			& tPlum = 0
			;
label "PlayersWon" = all_trees_empty & raven > 0;
label "RavenWon" = !all_trees_empty & raven = 0;

// rewards
rewards "Steps"
	s=0 : 1;
endrewards

