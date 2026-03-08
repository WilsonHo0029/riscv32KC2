
#include <metal/interrupt.h>
#include <encoding.h>

void metal_interrupt_enable(int id){
    
    switch(id) {
        case METAL_TIMER_INT :
            set_csr(mie, MIP_MTIP);
            break;
        case METAL_EXTERNAL_INT : 
            set_csr(mie, MIP_MEIP);
            break;        
        case METAL_SOFTWARE_INT : 
            set_csr(mie, MIP_MSIP);
            break;   
        case METAL_ALL_INT :
            set_csr(mie, MIP_MTIP | MIP_MEIP | MIP_MSIP);           
            break;                       
        case METAL_GENERAL_INT :
            set_csr(mstatus, MSTATUS_MIE);       
            break;
    }
}

void metal_interrupt_disable(int id){
    
    switch(id) {
        case METAL_TIMER_INT :
            clear_csr(mie, MIP_MTIP);
            break;
        case METAL_EXTERNAL_INT : 
            clear_csr(mie, MIP_MEIP);
            break;        
        case METAL_SOFTWARE_INT : 
            clear_csr(mie, MIP_MSIP);
            break; 
        case METAL_ALL_INT :
            clear_csr(mie, MIP_MTIP | MIP_MEIP | MIP_MSIP);           
            break;                        
        case METAL_GENERAL_INT :
            clear_csr(mstatus, MSTATUS_MIE);       
            break; 
    }
}