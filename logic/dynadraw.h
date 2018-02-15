#ifndef DYNADRAW_H
#define DYNADRAW_H

/*
 *	dynadraw -
 *
 *	     Use a simple dynamics model to create calligraphic strokes.
 *
 *
    To compile:
        cc dynadraw.c -o dynadraw -lgl -lm
 *
 *	leftmouse   - used for drawing
 *	middlemouse - clears page
 *	rightmouse  - menu
 *
 *	uparrow     - wider strokes
 *	downarrow   - narrower strokes
 *
 *				Paul Haeberli - 1989
 *
 */

#include <QtMath>

class DynaDraw
{

public:
    DynaDraw();

    int SLIDERHIGH = 15;
    int SLIDERLEFT = 200;
    float TIMESLICE = 0.005;
    int MAXPOLYS = 50000;

    struct filter {
        float curx, cury;
        float velx, vely, vel;
        float accx, accy, acc;
        float angx, angy;
        float mass, drag;
        float lastx, lasty;
        int fixedangle;
    };

    //QList<filter>   mouse;
    filter            mouse;

    float initwidth = 1.5;
    float width;
    float odelx, odely;
    float curmass, curdrag;
//TODO    float polyverts[4*2*MAXPOLYS];
    int npolys;
    long xsize, ysize;
    long xorg, yorg;

    float filtersetpos(filter *f,float x,float y) {
        f->curx = x;
        f->cury = y;
        f->lastx = x;
        f->lasty = y;
        f->velx = 0.0;
        f->vely = 0.0;
        f->accx = 0.0;
        f->accy = 0.0;

    }

    float filterapply(filter *f,float mx,float my) {
        float mass, drag;
        float fx, fy, force;

    /* calculate mass and drag */
        mass = flerp(1.0,160.0,curmass);
        drag = flerp(0.00,0.5,curdrag*curdrag);

    /* calculate force and acceleration */
        fx = mx-f->curx;
        fy = my-f->cury;
        f->acc = qSqrt(fx*fx+fy*fy);
        if(f->acc<0.000001)
        return 0;
        f->accx = fx/mass;
        f->accy = fy/mass;

    /* calculate new velocity */
        f->velx += f->accx;
        f->vely += f->accy;
        f->vel = qSqrt(f->velx*f->velx+f->vely*f->vely);
        f->angx = -f->vely;
        f->angy = f->velx;
        if(f->vel<0.000001)
        return 0;

    /* calculate angle of drawing tool */
        f->angx /= f->vel;
        f->angy /= f->vel;
        if(f->fixedangle) {
        f->angx = 0.6;
        f->angy = 0.2;
        }

    /* apply drag */
        f->velx = f->velx*(1.0-drag);
        f->vely = f->vely*(1.0-drag);

    /* update position */
        f->lastx = f->curx;
        f->lasty = f->cury;
        f->curx = f->curx+f->velx;
        f->cury = f->cury+f->vely;
        return 1;
    }

    float flerp(float f0,float f1,float p)
    {
        return ((f0*(1.0-p))+(f1*p));
    }

    void makeframe()
    {
        //reshapeviewport();
        //getsize(&xsize,&ysize);
        //getorigin(&xorg,&yorg);
        curmass = 0.5;
        curdrag = 0.15;
        initbuzz();
        width = initwidth;
        mouse.fixedangle = 1;
        clearscreen();
    }

    void clearscreen()
    {
        int x, y;

        //ortho2(0.0,1.25,0.0,1.0);
        //color(51);
        //setpattern(0);
        //clear();
        npolys = 0;
        showsettings();
        //color(0);
    }

    void showsettings()
    {
        char str[256];
        int xpos;

//        ortho2(-0.5,xsize-0.5,-0.5,ysize-0.5);
//        color(51);
//        rectfi(0,0,xsize,2*SLIDERHIGH);
//        color(0);
//        sprintf(str,"Mass %g",curmass);
//        cmov2i(20,3+1*SLIDERHIGH);
//        charstr(str);
//        sprintf(str,"Drag %g",curdrag);
//        cmov2i(20,3+0*SLIDERHIGH);
//        charstr(str);
//        move2i(SLIDERLEFT,0);
//        draw2i(SLIDERLEFT,2*SLIDERHIGH);
//        move2i(0,1*SLIDERHIGH);
//        draw2i(xsize,1*SLIDERHIGH);
//        move2i(0,2*SLIDERHIGH);
//        draw2i(xsize,2*SLIDERHIGH);
//        color(1);
//        xpos = SLIDERLEFT+curmass*(xsize-SLIDERLEFT);
//        rectfi(xpos,1*SLIDERHIGH,xpos+4,2*SLIDERHIGH);
//        xpos = SLIDERLEFT+curdrag*(xsize-SLIDERLEFT);
//        rectfi(xpos,0*SLIDERHIGH,xpos+4,1*SLIDERHIGH);
//        ortho2(0.0,1.25,0.0,1.0);
    }

    void drawsegment(filter *f) {
        float delx, dely;
        float wid, *fptr;
        float px, py, nx, ny;

        wid = 0.04-f->vel;
        wid = wid*width;
        if(wid<0.00001)
            wid = 0.00001;
        delx = f->angx*wid;
        dely = f->angy*wid;

        //color(0);
        px = f->lastx;
        py = f->lasty;
        nx = f->curx;
        ny = f->cury;

// TODO       fptr = polyverts+8*npolys;
        //bgnpolygon();
        fptr[0] = px+odelx;
        fptr[1] = py+odely;
        //v2f(fptr);
        fptr += 2;
        fptr[0] = px-odelx;
        fptr[1] = py-odely;
        //v2f(fptr);
        fptr += 2;
        fptr[0] = nx-delx;
        fptr[1] = ny-dely;
        //v2f(fptr);
        fptr += 2;
        fptr[0] = nx+delx;
        fptr[1] = ny+dely;
        //v2f(fptr);
        fptr += 2;
        //endpolygon();
        npolys++;
        if(npolys>=MAXPOLYS) {
        //fprintf(stderr,"out of polys - increase the define MAXPOLYS\n");
        npolys--;
        }
        fptr -= 8;
        //bgnclosedline();
        //v2f(fptr);
        fptr += 2;
        //v2f(fptr);
        fptr += 2;
        //v2f(fptr);
        fptr += 2;
        //v2f(fptr);
        fptr += 2;
        //endclosedline();
        odelx = delx;
        odely = dely;

    }

    void incWidth(){
        initwidth *= 1.414213;
        width = initwidth;
    }

    void decWidth(){
        initwidth /= 1.414213;
        width = initwidth;
    }

    void flipfixedangle(){
        mouse.fixedangle = 1-mouse.fixedangle;
    }

    float p, mx, my;
    void drawBrush()
    {
        makeframe();
        my = getmousey();
        if(my>0*SLIDERHIGH && my<2*SLIDERHIGH) {
            if(my>SLIDERHIGH) {
                //while(getbutton(LEFTMOUSE)) {
                    p = paramval();
                    if(p != curmass) {
                        curmass = p;
                        showsettings();
                    }
                //}
            } else {
                //while(getbutton(LEFTMOUSE)) {
                    p = paramval();
                    if(p != curdrag) {
                        curdrag = p;
                        showsettings();
                    }
                //}
            }
        } else {
            mx = 1.25*fgetmousex();
            my = fgetmousey();
            filtersetpos(&mouse,mx,my);
            odelx = 0.0;
            odely = 0.0;
            //while(getbutton(LEFTMOUSE)) {
                mx = 1.25*fgetmousex();
                my = fgetmousey();
                if(filterapply(&mouse,mx,my)) {
                    drawsegment(&mouse);
                    //color(0);
                    buzz();
                }
            //}
        }
    }

    float paramval()
    {
        float p;

        p = (float)(getmousex()-SLIDERLEFT)/(xsize-SLIDERLEFT);
        if(p<0.0)
        return 0.0;
        if(p>1.0)
        return 1.0;
        return p;
    }

    float fgetmousex()
    {
//TODO        return ((float)getvaluator(MOUSEX)-xorg)/(float)xsize;
        return 1.0;
    }

    float fgetmousey()
    {
//TODO        return ((float)getvaluator(MOUSEY)-yorg)/(float)ysize;
        return 1.0;
    }

    int getmousex()
    {
//TODO        return getvaluator(MOUSEX)-xorg;
        return 1.0;
    }

    int getmousey()
    {
//TODO        return getvaluator(MOUSEY)-yorg;
        return 1.0;
    }

    int buzztemp, buzzmax;

    /* this returns the time in 100ths of a sec since the system was rebooted  */
    unsigned long getltime()
    {
//TODO        struct tms ct;

//        return times(&ct);
        return 1.0;
    }

    /* this should spin for TIMESLICE seconds afteer "calibration" */
    void buzz()
    {
        int i;

        for(i=0; i<buzzmax; i++)
        buzztemp++;
    }

    /* this "calibrates" the buzz loop to determine buzzmax */
    void initbuzz()
    {
        long t0, t1;

        buzzmax = 1000000;
//TODO        sginap(10);	/* sleep for 10/100 of a second */
        t0 = getltime();
        buzz();
        t1 = getltime();
        buzzmax = TIMESLICE*(100.0*1000000.0)/(t1-t0);
    }



};

#endif // DYNADRAW_H
