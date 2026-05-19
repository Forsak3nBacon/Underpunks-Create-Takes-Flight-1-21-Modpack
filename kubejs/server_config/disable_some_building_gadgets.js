ServerEvents.recipes(event => {
    event.remove({
        output: 'buildinggadgets2:gadget_cut_paste'
    })

    event.remove({
        output: 'buildinggadgets2:gadget_destruction'
    })

    
    console.info('Some Building Gadgets have been disabled.')
})
