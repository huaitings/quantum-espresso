1. Prepare your element parameter in HEA.pm
	
2. Use atomsk create all structure data(ex: element , binary element, HEA)
    *element        : run single.pl
    *binary element : run binary.pl
    *HEA            : run HEA_initial.pl
                      run HEA_swap.pl
                      run HEA_optimize.pl
3.optimize your structure
    * Opt.pl : optimize all of your structures  
    * Opt.in: your template of QE optimization input
4. All structure need to optimize
    * MD.pl : can transfer all data to QE input,and run optimization (get QE output)
    * makedata.pl    : can get data after optimization 
    * MDdata.pl : can make ovito's animation
5. After optimize , you can run MD, void, surface  
   * surface.pl : can transfer optimization data to surface input,and run 
   * void.pl : can transfer optimization data to void input,and run MD
6. After run MD and elastic constant,you can get many refdata ,refdata is 
   DFT result, you need to transfer these refdata to DeepMD input (coord.raw , force.raw , 
  energy.raw , virial.raw)
   * virial.raw : if you have elastic constant , you have to consider the virial
   *QE2deep.pl & raw_to_set: can transfer qeoutput  
7.After DeepMD, you can get the same result as DFT 
